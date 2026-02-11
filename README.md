# Swarm Image Processing with Jenkins

This project demonstrates a real-life, industry-grade pipeline using **Jenkins Orchestration** to perform parallel image processing across a swarm of **AWS EC2 t3.micro** instances. It utilizes distributed computing to split a high-resolution image into a 2x2 matrix, process quadrants in parallel on multiple worker nodes, and reassemble them into a final checkered result.

## 1. Infrastructure Setup (AWS Launch Templates)

To ensure stability on 1GB RAM instances, the following specifications and UserData scripts include custom **Swap Memory** and **Java Heap** configurations.

### A. Jenkins Master Node

* **Template Name:** `Jenkins_Swarm_Master`
* **AMI:** Amazon Linux 2023
* **Instance Type:** `t3.micro` (1 vCPU, 1 GiB RAM)
* **Storage:** 12GB EBS (gp3)
* **Security Group:** Inbound Port `22` (SSH) and Port `8080` (Jenkins UI).
* **Credit Specification:** Standard
* **UserData:** [`user_data_master.sh`](https://github.com/PradyotC/Swarm_Image_Processing/blob/main/user_data_master.sh) *(Ensures 4GB Swap and 512MB Java Heap limit)*

### B. Jenkins Slave Nodes (Workers)

* **Template Name:** `Jenkins_Swarm_Slave`
* **AMI:** Amazon Linux 2023
* **Instance Type:** `t3.micro` (1 vCPU, 1 GiB RAM)
* **Storage:** 8GB EBS (gp3)
* **Security Group:** Inbound Port `22` (SSH).
* **Credit Specification:** Standard
* **UserData:** [`user_data_slave.sh`](https://github.com/PradyotC/Swarm_Image_Processing/blob/main/user_data_slave.sh) *(Ensures 2GB Swap and pre-installs ImageMagick)*

---

## 2. Deployment & Authentication

1. **Launch Instances:** Create **1 Master** and **2 Slaves** from your respective templates.
2. **Wait:** Allow 2-3 minutes for the UserData scripts to complete software installation and system tuning.
3. **Initial Unlock:** * SSH into the Master and run `sudo cat /var/lib/jenkins/secrets/initialAdminPassword` and copy the initial password.
* Navigate to `http://<MASTER_PUBLIC_IP>:8080` to complete the setup wizard and install default plugins.


4. **SSH Key Exchange:**
* **On Master:** Run this command to generate a ready-to-use installation command:
  
  ```bash
  echo "echo \"$(cat ~/.ssh/id_ed25519.pub)\" >> ~/.ssh/authorized_keys"
  ```
* **Copy the output:** The terminal will print a line starting with `echo "ssh-ed25519...`. Copy this entire line.
* **On Slaves:** SSH into **both Slaves** and simply **paste** that copied line into the terminal and hit Enter. This automatically adds the Master's key to the authorized list.


---

## 3. Node Connection Settings

### Slave-1 Configuration

1. Navigate to **Manage Jenkins > Nodes > New Node**.
2. **Name:** `slave-1` | **Type:** `Permanent Agent`.
3. **Remote Root Directory:** `/home/ec2-user/jenkins_agent/`.
4. **Labels:** `slave-1`.
5. **Launch Method:** `Launch agents via SSH`.
* **Host:** `<PUBLIC_IP_OF_SLAVE_1>`
* **Credentials:** Add new (Username: `ec2-user`, Private Key: Paste contents of Master's `~/.ssh/id_ed25519`).
* **Host Key Verification:** `Non verifying Verification Strategy`.


6. **Advanced (Java Optimization):**
* **JavaPath:** `"/usr/bin/java" -Djava.io.tmpdir=/home/ec2-user/jenkins_tmp -Xmx512m -Xms512m -XX:+UseSerialGC`


7. **Save** and ensure the node comes online.

### Slave-2 Configuration

1. **New Node** > **Name:** `slave-2`.
2. **Type:** Select `Copy Existing Node` and type `slave-1`.
3. **Change:** Update the **Host IP** to Slave-2's public IP and change the **Label** to `slave-2`.

---

## 4. Pipeline Configuration

1. **Create Job:** `New Item` > `pipeline-1` > `Pipeline`.
2. **Log Rotation:** Check `Discard old builds`.
* Days to keep: `3` | Max builds: `3`.


3. **Pipeline Definition:**
* **SCM:** `Git`
* **Repository URL:** `https://github.com/PradyotC/Swarm_Image_Processing.git`
* **Branch:** `*/main`
* **Script Path:** `Jenkinsfile`



---

## 5. Build and Results

Click **Build Now**. Jenkins will coordinate the following:

* **Master:** Splits image into 4 quadrants.
* **Slaves:** Process quadrants in parallel (Diagonal 1 on Slave-1, Diagonal 2 on Slave-2).
* **Master:** Reassembles the matrix.

**View Result:**
`http://<MASTER_PUBLIC_IP>:8080/userContent/checker_result.jpg`
