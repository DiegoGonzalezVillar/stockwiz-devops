from flask import Flask, request, jsonify

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


@app.route("/products/<int:product_id>", methods=["PUT"])
def update_product(product_id):
    for p in products:
        if p["id"] == product_id:
            p.update(request.json)
            return jsonify(p)
    return jsonify({"error": "Product not found"}), 404


@app.route("/products/<int:product_id>", methods=["DELETE"])
def delete_product(product_id):
    global products
    products = [p for p in products if p["id"] != product_id]
    return jsonify({"message": "Deleted"}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8001)
