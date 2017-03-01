docker-containers:
  lookup:
    wordpress:
      image: "wordpress"
      runoptions:
        - "-e WORDPRESS_DB_HOST=wordpress-db.demo.local"
        - "-e WORDPRESS_DB_USER=admin"
        - "-e WORDPRESS_DB_PASSWORD=Xg4gc30b"
        - "-p 80:80"
        - "--rm"