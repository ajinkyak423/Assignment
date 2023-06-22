# Step: 1 Create a Terraform script to deploy a VM. The VM should be in public subnet.

- Initially Terraform and AWS CLI setup is done using official documentation
- I have written a Terraform Script utilizing concept of variable file for easy update and maintains
- Explanation of script:
    1. VPC (**`aws_vpc`**):
        - It creates a VPC with the specified CIDR block and enables DNS hostnames.
    2. Internet Gateway (**`aws_internet_gateway`**):
        - It creates an internet gateway and associates it with the VPC.
    3. Public Subnet (**`aws_subnet`**):
        - It creates a public subnet within the VPC with the specified CIDR block.
        - The **`map_public_ip_on_launch`** attribute is set to true, which automatically assigns a public IP to instances launched in this subnet.
    4. Public Route Table (**`aws_route_table`**):
        - It creates a public route table associated with the VPC.
        - It defines a default route (**`0.0.0.0/0`**) that directs traffic to the internet gateway.
    
    1. Public Subnet Route Table Association (**`aws_route_table_association`**):
        - It associates the public subnet with the public route table.
    2. Private Subnet (**`aws_subnet`**):
        - It creates a private subnet within the VPC with the specified CIDR block.
        - The **`map_public_ip_on_launch`** attribute is set to false, which means instances in this subnet won't have a public IP automatically assigned.
    3. Public Security Group (**`aws_security_group`**):
        - It creates a security group allowing inbound SSH (port 22) and HTTP (port 80) traffic from any IP (**`0.0.0.0/0`**).
        - It allows all outbound traffic (**`0.0.0.0/0`**).
    4. Private Key (**`tls_private_key`**):
        - It generates an RSA private key to be used for SSH access to the EC2 instance.
    5. Key Pair (**`aws_key_pair`**):
        - It creates an AWS key pair with the generated RSA public key.
    6. Local File (**`local_file`**):
        - It saves the generated RSA private key to a local file named "TfKey".
    7. EC2 Instance (**`aws_instance`**):
        - It creates an EC2 instance using the specified AMI, instance type, subnet, security group, public IP association, key pair, and tags.
             

# Step: 2 In the same VM Create a Dockerfile to deploy Apache webserver + PHP + Wordpress.

Docker image with Apache and PHP, installs required PHP extensions, and downloads and extracts the WordPress files. Here's a breakdown of the Dockerfile:

1. Base Image:
    - It starts with the `php:7.4-apache` base image, which includes Apache and PHP.
2. ARG Variables:
    - It sets the `WORDPRESS_VERSION` and `WORDPRESS_DOWNLOAD_URL` as ARG variables. You can specify the WordPress version and download URL during the build process.
3. Working Directory:
    - It sets the working directory to `/var/www/html`.
4. Copy WordPress Files:
    - It copies the WordPress files from the build context to the working directory in the container. The `.` specifies that you are copying all the files from the build context.
5. Install PHP Extensions:
    - It installs the `mysqli` PHP extension using the `docker-php-ext-install` command. This extension is required by WordPress for database connectivity.
6. Download and Extract WordPress:
    - It uses the `curl` command to download the WordPress archive from the specified `WORDPRESS_DOWNLOAD_URL`.
    - The `tar` command extracts the downloaded archive and the `-strip-components=1` option removes the top-level directory from the extracted files.
    - Finally, the downloaded WordPress archive is removed using the `rm` command.
7. Set Entrypoint:
    - It sets the entrypoint to `apache2-foreground`, which starts the Apache web server when the container is run.

To build an image from this Dockerfile, navigate to the directory containing the Dockerfile and run the `docker build` command. For example:

```
docker build -t wordpress:v1 .

```

This command builds the Docker image with the tag `wordpress:v1` using the Dockerfile in the current directory (`.`). You can replace `wordpress:v1` with the desired image name and tag.

Once the image is built, you can run a container from it using the `docker run` command, as you did before.

# Step: 3 Build the docker image, tag the image and push the docker image to Docker Hub and run the container.

To push your Docker image to Docker Hub, I  followed these steps:

1. Log in to Docker Hub using the Docker CLI. Open your terminal or command prompt and run the following command:
    
    ```
    docker login
    ```
    
    Enter your Docker Hub username and password when prompted.
    
2. Tag your local Docker image with your Docker Hub username and the desired repository name. Use the following command:
    
    ```
    docker tag wordpress:v1 ajinkyak423/wordpress:v1
    ```
    
    Replace `<your-dockerhub-username>` with your Docker Hub username, `<repository-name>` with the name you want to give to your repository, and `<tag>` with the desired tag for your image.
    
3. Push the tagged image to Docker Hub using the following command:
    
    ```
    docker push ajinkyak423/wordpress:v1
    ```
    
    This command will push the Docker image to Docker Hub. The image will be stored in your Docker Hub account, and you can access it from anywhere.
    

# Step: 4 Deploy the RDS on AWS/Azure and it should be on private subnet.

I have created RDS database using AWS console but we can also use aws cli to do it via command line.

To create a free RDS database in a private subnet named "webapache," follow these steps:

1. Ensure you have the necessary AWS CLI installed and configured on your system.
2. Create a security group for the RDS database to allow access from your desired sources. Run the following command:
    
    ```
    aws ec2 create-security-group --group-name RDS-Security-Group --description "RDS Security Group"
    
    ```
    
    This command will return the security group ID. Make note of it for later use.
    
3. Configure the inbound rules for the security group to allow the necessary database connections. For example, to allow MySQL connections from your application server's security group, run the following command:
    
    ```
    aws ec2 authorize-security-group-ingress --group-id <security-group-id> --protocol tcp --port 3306 --source-group <application-server-security-group-id>
    
    ```
    
    Replace `<security-group-id>` with the security group ID you obtained in step 2, and `<application-server-security-group-id>` with the security group ID of your application server.
    
4. Create a subnet group for the RDS database. Run the following command:
    
    ```
    aws rds create-db-subnet-group --db-subnet-group-name RDS-Subnet-Group --db-subnet-group-description "RDS Subnet Group" --subnet-ids <comma-separated-subnet-ids>
    
    ```
    
    Replace `<comma-separated-subnet-ids>` with the IDs of the private subnets where you want to place the RDS database. Separate multiple subnet IDs with commas.
    
5. Create the RDS database instance. Run the following command:
    
    ```
    aws rds create-db-instance --db-instance-identifier webapache --db-instance-class db.t3.micro --engine mysql --master-username <db-username> --master-user-password <db-password> --allocated-storage 20 --db-subnet-group-name RDS-Subnet-Group --vpc-security-group-ids <comma-separated-security-group-ids> --multi-az false --publicly-accessible false
    
    ```
    
    Replace `<db-username>` and `<db-password>` with the desired username and password for the database.
    Replace `<comma-separated-security-group-ids>` with the security group IDs you want to associate with the RDS instance. Separate multiple security group IDs with commas.
    
6. Wait for the RDS database creation to complete. You can check the status using the following command:
    
    ```
    aws rds describe-db-instances --db-instance-identifier webapache --query "DBInstances[0].DBInstanceStatus"
    
    ```
    
    Wait until the status returns "available" before proceeding.
    

Once the RDS database is created, you can connect to it using the provided endpoint, username, and password. Remember that the database is in a private subnet and not publicly accessible, so you'll need to ensure your application server has the necessary network connectivity to reach the RDS database.

# Step: 5 Connect your Wordpress container with RDS database

Run docker container using following command

```yaml
docker run -e WORDPRESS_DB_HOST=<rds_host> -e WORDPRESS_DB_USER=<db_user> -e WORDPRESS_DB_PASSWORD=<db_password> -e WORDPRESS_DB_NAME=<db_name> -p 80:80 -d <image_name>
```

To connect your WordPress container with an RDS database, you need to provide the necessary database connection details in the WordPress configuration file (`wp-config.php`). Here's how you can do it:

1. Open the `wp-config.php` file in your WordPress container for editing. You can use the following command to access the container's shell:
    
    ```
    docker exec -it <container_name> /bin/bash
    
    ```
    
    Replace `<container_name>` with the name or ID of your WordPress container.
    
2. Locate the database configuration section in the `wp-config.php` file. It should look similar to the following:
    
    ```
    define('DB_NAME', 'your_database_name');
    define('DB_USER', 'your_database_username');
    define('DB_PASSWORD', 'your_database_password');
    define('DB_HOST', 'your_database_host');
    
    ```
    
3. Replace the placeholder values with the actual database connection details. For example:
    
    ```
    define('DB_NAME', 'your_rds_database_name');
    define('DB_USER', 'your_rds_username');
    define('DB_PASSWORD', 'your_rds_password');
    define('DB_HOST', 'your_rds_endpoint');
    
    ```
    
    - `your_rds_database_name`: The name of your RDS database.
    - `your_rds_username`: The username for accessing the RDS database.
    - `your_rds_password`: The password for the RDS database user.
    - `your_rds_endpoint`: The endpoint URL or hostname of your RDS database.
4. Save the changes to the `wp-config.php` file and exit the container shell.
5. Restart the WordPress container to apply the configuration changes:
    
    ```
    docker restart <container_name>
    
    ```
    
    Replace `<container_name>` with the name or ID of your WordPress container.
    

After the container restarts, WordPress should be able to connect to the RDS database using the provided configuration. Ensure that the RDS database security group allows incoming connections from the WordPress container's security group. Also, make sure that the network configuration of your EC2 instance or Docker setup allows connectivity between the WordPress container and the RDS database.

# Results:

- We have created Terraform file in which initially do inti and do plan
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/Screenshot%202023-06-21%20220136.png)
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/vpcplan.png)
    

- Using terraform apply we created all the infrastructure
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/allcreated.png)
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/vpc.png)
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/gateway.png)
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/route.png)
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/subnet.png)
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/vmcreation.png)
    
- Then we create docker file and build image and push it on Docker hub
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/ogdockerimagepush.png)
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/1dockerhub.png)
    
- We can see that WordPress container is accessible on Ip address of Ec2 instance
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/wordpress.png)
    

- We are give option to add credentials to WordPress using our RDS database
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/w.png)
    
- If we are creating wp-config.php file manually we get this messages
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/work.png)
    
    ![Untitled](https://github.com/ajinkyak423/assignment/blob/main/screenshots/working.png)
    

# Conclusion:

I have implemented all the required steps of Terraform and build infrastructure while creating docker image and pushing it on docker hub. Also we can access WordPress and connect RDS database with config file.
