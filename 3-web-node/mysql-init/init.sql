-- Se ejecuta solo la primera vez que se crea el volumen de MySQL.
-- MYSQL_DATABASE ya la crea la imagen; aquí creamos la tabla y los datos de ejemplo.
SET NAMES utf8mb4;
CREATE TABLE IF NOT EXISTS productos (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  categoria VARCHAR(50) NOT NULL,
  precio DECIMAL(8,2) NOT NULL,
  stock INT NOT NULL DEFAULT 0
) CHARACTER SET utf8mb4;

INSERT INTO productos (nombre, categoria, precio, stock) VALUES
  ('Portátil 15"', 'Informática', 649.90, 12),
  ('Ratón inalámbrico', 'Periféricos', 19.95, 80),
  ('Teclado mecánico', 'Periféricos', 59.00, 35),
  ('Monitor 24"', 'Informática', 139.99, 20),
  ('Auriculares Bluetooth', 'Audio', 45.50, 50),
  ('Webcam Full HD', 'Periféricos', 32.75, 28);
