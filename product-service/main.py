from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel, Field
from typing import Optional, List
import asyncpg
import redis.asyncio as redis
import json
import os
from contextlib import asynccontextmanager

app = Flask(__name__)

# -----------------------------
# Base de datos en memoria
# -----------------------------
products = [
    {"id": 1, "name": "Laptop Dell XPS 13", "description": "Ultrabook potente y ligera", "price": 1299.99, "category": "Electronics"},
    {"id": 2, "name": "Mouse Logitech MX Master", "description": "Mouse ergonómico inalámbrico", "price": 99.99, "category": "Electronics"},
    {"id": 3, "name": "Teclado Mecánico", "description": "Teclado mecánico RGB", "price": 149.99, "category": "Electronics"},
    {"id": 4, "name": "Monitor 4K", "description": "Monitor 27 pulgadas 4K", "price": 499.99, "category": "Electronics"},
    {"id": 5, "name": "Webcam HD", "description": "Cámara web Full HD", "price": 79.99, "category": "Electronics"},
]

# -----------------------------
# Endpoints
# -----------------------------

@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/products", methods=["GET"])
def get_products():
    return jsonify(products)


@app.route("/products/<int:product_id>", methods=["GET"])
def get_product(product_id):
    for p in products:
        if p["id"] == product_id:
            return jsonify(p)
    return jsonify({"error": "Product not found"}), 404


@app.route("/products", methods=["POST"])
def create_product():
    new_prod = request.json
    new_prod["id"] = max(p["id"] for p in products) + 1
    products.append(new_prod)
    return jsonify(new_prod), 201


# Actualizar producto
@app.put("/products/{product_id}", response_model=Product)
async def update_product(
    product_id: int,
    product: ProductUpdate,
    db: asyncpg.Connection = Depends(get_db)
):
    # Verificar que existe
    exists = await db.fetchrow("SELECT id, category FROM products WHERE id = $1", product_id)
    if not exists:
        raise HTTPException(status_code=404, detail="Product not found")
    
    old_category = exists['category']
    
    # Construir query dinámicamente
    updates = []
    values = []
    counter = 1
    
    if product.name is not None:
        updates.append(f"name = ${counter}")
        values.append(product.name)
        counter += 1
    if product.description is not None:
        updates.append(f"description = ${counter}")
        values.append(product.description)
        counter += 1
    if product.price is not None:
        updates.append(f"price = ${counter}")
        values.append(product.price)
        counter += 1
    if product.category is not None:
        updates.append(f"category = ${counter}")
        values.append(product.category)
        counter += 1
    
    if not updates:
        raise HTTPException(status_code=400, detail="No fields to update")
    
    updates.append(f"updated_at = CURRENT_TIMESTAMP")
    values.append(product_id)
    
    query = f"""
        UPDATE products
        SET {', '.join(updates)}
        WHERE id = ${counter}
        RETURNING *
    """
    
    row = await db.fetchrow(query, *values)
    updated_product = dict(row)
    
    # Invalidar caches
    await redis_client.delete(f"product:{product_id}")
    await redis_client.delete("products:all")
    await redis_client.delete(f"products:all:{old_category}")
    if product.category:
        await redis_client.delete(f"products:all:{product.category}")
    
    return updated_product


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
