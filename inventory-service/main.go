package main

import (
	"encoding/json"
	"net/http"
	"strconv"
)

type InventoryItem struct {
	ID        int    `json:"id"`
	ProductID int    `json:"product_id"`
	Quantity  int    `json:"quantity"`
	Warehouse string `json:"warehouse"`
}

var inventory = []InventoryItem{
	{ID: 1, ProductID: 1, Quantity: 50, Warehouse: "Warehouse A"},
	{ID: 2, ProductID: 2, Quantity: 150, Warehouse: "Warehouse A"},
	{ID: 3, ProductID: 3, Quantity: 75, Warehouse: "Warehouse B"},
	{ID: 4, ProductID: 4, Quantity: 30, Warehouse: "Warehouse A"},
	{ID: 5, ProductID: 5, Quantity: 100, Warehouse: "Warehouse B"},
}

func main() {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})

	http.HandleFunc("/inventory", func(w http.ResponseWriter, r *http.Request) {
		json.NewEncoder(w).Encode(inventory)
	})

	http.HandleFunc("/inventory/", func(w http.ResponseWriter, r *http.Request) {
		idStr := r.URL.Path[len("/inventory/"):]
		id, _ := strconv.Atoi(idStr)

		for _, item := range inventory {
			if item.ID == id {
				json.NewEncoder(w).Encode(item)
				return
			}
		}

		http.Error(w, "Item not found", 404)
	})

	http.ListenAndServe(":8002", nil)
}
