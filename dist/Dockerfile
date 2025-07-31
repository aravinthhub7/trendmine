# Use Nginx base image
FROM nginx:alpine

# Remove default Nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy all current static files into Nginx html directory
COPY . /usr/share/nginx/html

# Set permissions (optional but helpful)
RUN chmod -R 755 /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
