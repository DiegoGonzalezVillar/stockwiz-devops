package main

import (
	"context"
	"embed"
	"encoding/json"
	"fmt"
	"io"
	"io/fs"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
	"github.com/go-redis/redis/v8"
)

//go:embed static/*
var staticFiles embed.FS

var (
	productServiceURL   string
	inventoryServiceURL string
	redisClient         *redis.Client
	ctx                 = context.Background()
	httpClient          *http.Client
)

type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
}

type ProductWithInventory struct {
	ID          int     `json:"id"`
	Name        string  `json:"name"`
	Description *string `json:"description"`
	Price       float64 `json:"price"`
	Category    *string `json:"category"`
	Inventory   *struct {
		Quantity  int    `json:"quantity"`
		Warehouse string `json:"warehouse"`
	} `json:"inventory,omitempty"`
}

func main() {
	// Configuración de servicios
	productServiceURL = os.Getenv("PRODUCT_SERVICE_URL")
	if productServiceURL == "" {
		productServiceURL = "http://product-service:8001"
	}

	inventoryServiceURL = os.Getenv("INVENTORY_SERVICE_URL")
	if inventoryServiceURL == "" {
		inventoryServiceURL = "http://inventory-service:8002"
	}

	// Conectar a Redis
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "localhost:6379"
	}

	redisClient = redis.NewClient(&redis.Options{
		Addr:         redisURL,
		DB:           0,
		DialTimeout:  10 * time.Second,
		ReadTimeout:  30 * time.Second,
		WriteTimeout: 30 * time.Second,
		PoolSize:     10,
		MinIdleConns: 2,
	})

	if err := redisClient.Ping(ctx).Err(); err != nil {
		log.Println("⚠️ Redis not available, running without cache:", err)
		redisClient = nil
	} else {
		log.Println("✅ Connected to Redis")
	}

	// HTTP client
	httpClient = &http.Client{
		Timeout: 30 * time.Second,
		Transport: &http.Transport{
			MaxIdleConns:        100,
			MaxIdleConnsPerHost: 10,
			IdleConnTimeout:     90 * time.Second,
		},
	}

	log.Println("✅ API Gateway started successfully")

	r := chi.NewRouter()

	// Middlewares
	r.Use(middleware.Logger)
	r.Use(middleware.Recoverer)
	r.Use(middleware.Timeout(60 * time.Second))
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Compress(5))

	// CORS
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		ExposedHeaders:   []string{"Link"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	// Static files
	staticFS, _ := fs.Sub(staticFiles, "static")
	r.Handle("/static/*", http.StripPrefix("/static/", http.FileServer(http.FS(staticFS))))

	r.Get("/", serveIndex)
	r.Get("/health", healthCheck)

	// API routes
	r.Get("/api/products", proxyToProductService)
	r.Get("/api/products/{id}", getProductWithInventory)
	r.Post("/api/products", proxyToProductService)
	r.Put("/api/products/{id}", proxyToProductService)
	r.Delete("/api/products/{id}", proxyToProductService)

	r.Get("/api/inventory", proxyToInventoryService)
	r.Get("/api/inventory/{id}", proxyToInventoryService)
	r.Get("/api/inventory/product/{product_id}", proxyToInventoryService)
	r.Post("/api/inventory", proxyToInventoryService)
	r.Put("/api/inventory/{id}", proxyToInventoryService)
	r.Delete("/api/inventory/{id}", proxyToInventoryService)

	r.Get("/api/products-full", getAllProductsWithInventory)

	log.Println("🚀 API Gateway listening on :8000")
	log.Println("🌐 Frontend available at http://localhost:8000")
	if err := http.ListenAndServe(":8000", r); err != nil {
		log.Fatal(err)
	}
}

func serveIndex(w http.ResponseWriter, r *http.Request) {
	data, err := staticFiles.ReadFile("static/index.html")
	if err != nil {
		http.Error(w, "Could not load page", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html")
	if _, err := w.Write(data); err != nil {
		log.Println("error writing index.html:", err)
	}
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	productHealth := checkServiceHealth(productServiceURL + "/health")
	inventoryHealth := checkServiceHealth(inventoryServiceURL + "/health")

	response := map[string]interface{}{
		"status":  "healthy",
		"service": "api-gateway",
		"downstream_services": map[string]string{
			"product_service":   productHealth,
			"inventory_service": inventoryHealth,
		},
	}

	if err := json.NewEncoder(w).Encode(response); err != nil {
		log.Println("error writing health response:", err)
	}
}

func checkServiceHealth(url string) string {
	resp, err := httpClient.Get(url)
	if err != nil {
		return "unhealthy"
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		return "healthy"
	}
	return "unhealthy"
}

func proxyToProductService(w http.ResponseWriter, r *http.Request) {
	proxyRequest(w, r, productServiceURL)
}

func proxyToInventoryService(w http.ResponseWriter, r *http.Request) {
	proxyRequest(w, r, inventoryServiceURL)
}

func proxyRequest(w http.ResponseWriter, r *http.Request, targetURL string) {
	path := r.URL.Path
	if len(path) >= 4 && path[:4] == "/api" {
		path = path[4:]
	}

	url := targetURL + path
	if r.URL.RawQuery != "" {
		url += "?" + r.URL.RawQuery
	}

	proxyReq, err := http.NewRequest(r.Method, url, r.Body)
	if err != nil {
		sendError(w, http.StatusInternalServerError, "Error creating proxy request", err.Error())
		return
	}

	for key, values := range r.Header {
		for _, value := range values {
			proxyReq.Header.Add(key, value)
		}
	}

	resp, err := httpClient.Do(proxyReq)
	if err != nil {
		sendError(w, http.StatusBadGateway, "Error connecting to service", err.Error())
		return
	}
	defer resp.Body.Close()

	for key, values := range resp.Header {
		for _, value := range values {
			w.Header().Add(key, value)
		}
	}

	w.WriteHeader(resp.StatusCode)

	if _, err := io.Copy(w, resp.Body); err != nil {
		log.Println("error copying proxy response:", err)
	}
}

func getProductWithInventory(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	productID := chi.URLParam(r, "id")
	cacheKey := fmt.Sprintf("gateway:product_full:%s", productID)

	cached, err := redisClient.Get(ctx, cacheKey).Result()
	if err == nil {
		if _, err := w.Write([]byte(cached)); err != nil {
			log.Println("error writing cached product:", err)
		}
		return
	}

	productResp, err := httpClient.Get(fmt.Sprintf("%s/products/%s", productServiceURL, productID))
	if err != nil {
		sendError(w, http.StatusBadGateway, "Error connecting to product service", err.Error())
		return
	}
	defer productResp.Body.Close()

	if productResp.StatusCode != http.StatusOK {
		w.WriteHeader(productResp.StatusCode)
		if _, err := io.Copy(w, productResp.Body); err != nil {
			log.Println("error copying product body:", err)
		}
		return
	}

	var product ProductWithInventory
	if err := json.NewDecoder(productResp.Body).Decode(&product); err != nil {
		sendError(w, http.StatusInternalServerError, "Error decoding product", err.Error())
		return
	}

	inventoryResp, err := httpClient.Get(fmt.Sprintf("%s/inventory/product/%s", inventoryServiceURL, productID))
	if err == nil && inventoryResp.StatusCode == http.StatusOK {
		defer inventoryResp.Body.Close()

		var inventory struct {
			Quantity  int    `json:"quantity"`
			Warehouse string `json:"warehouse"`
		}

		if err := json.NewDecoder(inventoryResp.Body).Decode(&inventory); err == nil {
			product.Inventory = &struct {
				Quantity  int    `json:"quantity"`
				Warehouse string `json:"warehouse"`
			}{
				Quantity:  inventory.Quantity,
				Warehouse: inventory.Warehouse,
			}
		}
	}

	response, _ := json.Marshal(product)
	redisClient.Set(ctx, cacheKey, response, 3*time.Minute)

	if _, err := w.Write(response); err != nil {
		log.Println("error writing product response:", err)
	}
}

func getAllProductsWithInventory(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	cacheKey := "gateway:products_full:all"
	forceRefresh := r.URL.Query().Get("force_refresh") == "true"

	if !forceRefresh {
		cached, err := redisClient.Get(ctx, cacheKey).Result()
		if err == nil {
			if _, err := w.Write([]byte(cached)); err != nil {
				log.Println("error writing cached list:", err)
			}
			return
		}
	}

	productsResp, err := httpClient.Get(fmt.Sprintf("%s/products", productServiceURL))
	if err != nil {
		sendError(w, http.StatusBadGateway, "Error connecting to product service", err.Error())
		return
	}
	defer productsResp.Body.Close()

	if productsResp.StatusCode != http.StatusOK {
		w.WriteHeader(productsResp.StatusCode)
		if _, err := io.Copy(w, productsResp.Body); err != nil {
			log.Println("error copying products body:", err)
		}
		return
	}

	var products []ProductWithInventory
	if err := json.NewDecoder(productsResp.Body).Decode(&products); err != nil {
		sendError(w, http.StatusInternalServerError, "Error decoding products", err.Error())
		return
	}

	for i := range products {
		inventoryResp, err := httpClient.Get(fmt.Sprintf("%s/inventory/product/%d", inventoryServiceURL, products[i].ID))
		if err == nil && inventoryResp.StatusCode == http.StatusOK {
			defer inventoryResp.Body.Close()

			var inventory struct {
				Quantity  int    `json:"quantity"`
				Warehouse string `json:"warehouse"`
			}

			if err := json.NewDecoder(inventoryResp.Body).Decode(&inventory); err == nil {
				products[i].Inventory = &struct {
					Quantity  int    `json:"quantity"`
					Warehouse string `json:"warehouse"`
				}{
					Quantity:  inventory.Quantity,
					Warehouse: inventory.Warehouse,
				}
			}
		}
	}

	response, _ := json.Marshal(products)
	redisClient.Set(ctx, cacheKey, response, 3*time.Minute)

	if _, err := w.Write(response); err != nil {
		log.Println("error writing product list:", err)
	}
}

func sendError(w http.ResponseWriter, status int, message, detail string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(ErrorResponse{
		Error:   message,
		Message: detail,
	}); err != nil {
		log.Println("error writing error response:", err)
	}
}
