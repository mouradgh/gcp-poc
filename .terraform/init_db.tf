resource "local_file" "init_db" {
  filename = "${path.module}/init_db.sql"

  content = <<EOF
-- SQL initialization script
CREATE TABLE IF NOT EXISTS example (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);
EOF

  lifecycle {
    ignore_changes = [content]  # Ignore changes to the content
  }
} 