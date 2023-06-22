
# Use a base image with Apache and PHP
FROM php:7.4-apache

# Set the ARG variables for WordPress version and download URL
ARG WORDPRESS_VERSION=5.8
ARG WORDPRESS_DOWNLOAD_URL=https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz

# Set the working directory
WORKDIR /var/www/html

# Copy the WordPress files to the container
COPY . .

# Install required PHP extensions
RUN docker-php-ext-install mysqli

# Download and extract WordPress
RUN curl -o wordpress.tar.gz ${WORDPRESS_DOWNLOAD_URL} && \
    tar -xzf wordpress.tar.gz --strip-components=1 && \
    rm wordpress.tar.gz

# Set the entrypoint to start Apache
ENTRYPOINT ["apache2-foreground"]