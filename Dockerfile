# Use lightweight Nginx image
FROM nginx:alpine

# Copy application into Nginx web directory
COPY app/index.html /usr/share/nginx/html/index.html

# Expose application port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]