pipeline {
    agent none // We define agents per stage to strictly control where code runs

    stages {
        stage('Setup & Fetch (Master)') {
            agent { label 'built-in' } 
            steps {
                script {
                    // --- 1. The Logic: Fetch & Split ---
                    echo "Downloading High-Res Image..."
                    // Downloading a 2000px wide image from Unsplash
                    sh 'curl -L -o input.jpg "https://images.unsplash.com/photo-1707343843437-caacff5cfa74?q=80&w=2000&auto=format&fit=crop"'
                    
                    // Get height dynamically
                    def height = sh(script: "identify -format '%h' input.jpg", returnStdout: true).trim().toInteger()
                    def halfHeight = height / 2
                    
                    echo "Splitting image (Height: ${height}px)..."
                    // Crop Top Half
                    sh "convert input.jpg -crop x${halfHeight}+0+0 top.jpg"
                    // Crop Bottom Half
                    sh "convert input.jpg -crop x${halfHeight}+0+${halfHeight} bottom.jpg"
                    
                    // --- 2. Serialize to Java Stream (Send to Agents later) ---
                    stash includes: 'top.jpg', name: 'chunk-top'
                    stash includes: 'bottom.jpg', name: 'chunk-bottom'
                }
            }
        }
        
        stage('Distributed Swarm Processing') {
            parallel {
                // --- SLAVE 1: EDGE DETECTION ---
                stage('Edge Detect (Node A)') {
                    agent { label 'slave-1' } 
                    steps {
                        script {
                            // 1. Pull file from Master stream
                            unstash 'chunk-top'
                            
                            // 2. Process: Turn to Grayscale and detect edges (Pencil sketch look)
                            echo "Slave 1: Applying Edge Detection..."
                            sh 'convert top.jpg -colorspace Gray -edge 2 processed_top.jpg'
                            
                            // 3. Send back to Master stream
                            stash includes: 'processed_top.jpg', name: 'result-top'
                        }
                    }
                }
                
                // --- SLAVE 2: SEPIA TONE ---
                stage('Sepia Filter (Node B)') {
                    agent { label 'slave-2' } 
                    steps {
                        script {
                            // 1. Pull file from Master stream
                            unstash 'chunk-bottom'
                            
                            // 2. Process: Apply Sepia (Old Photo look)
                            echo "Slave 2: Applying Sepia Tone..."
                            sh 'convert bottom.jpg -sepia-tone 80% processed_bottom.jpg'
                            
                            // 3. Send back to Master stream
                            stash includes: 'processed_bottom.jpg', name: 'result-bottom'
                        }
                    }
                }
            }
        }
        
        stage('Stitch & Publish (Master)') {
            agent { label 'built-in' } // Back to Master
            steps {
                script {
                    // 1. Retrieve the processed chunks from the Java stream
                    unstash 'result-top'
                    unstash 'result-bottom'
                    
                    // 2. Stitch them back together vertically (-append)
                    echo "Stitching halves together..."
                    sh 'convert -append processed_top.jpg processed_bottom.jpg final_output.jpg'
                    
                    // 3. Host it!
                    // We move it to the userContent folder which Jenkins serves automatically
                    sh 'cp final_output.jpg /var/lib/jenkins/userContent/swarm_result.jpg'
                    
                    echo "----------------------------------------------------------"
                    echo "SUCCESS! View your distributed processing result here:"
                    echo "${JENKINS_URL}userContent/swarm_result.jpg"
                    echo "----------------------------------------------------------"
                }
            }
        }
    }
}
