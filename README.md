# Karamelized cookbook to deploy Hopsworks monitoring infrastructure 

## Steps to deploying a new dashboard

1. Create `.json` file in `dashboards` folder.

2. Restart consul service 
    ```sh
    systemctl restart consul
    ```