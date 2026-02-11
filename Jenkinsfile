pipeline {
    agent none 

    stages {
        stage('Setup & 2x2 Split (Master)') {
            agent { label 'built-in' } 
            steps {
                script {
                    echo "Downloading Source Image..."
                    sh 'curl -L -o input.jpg "https://picsum.photos/1600/800"'
                    
                    echo "Splitting into 4 Quadrants (Checkered Split)..."
                    // The '@' symbol tells ImageMagick to split into equal chunks based on the number (2x2 = 4 chunks)
                    // It outputs: chunk-0.jpg (TL), chunk-1.jpg (TR), chunk-2.jpg (BL), chunk-3.jpg (BR)
                    sh 'convert input.jpg -crop 2x2@ +repage chunk-%d.jpg'
                    
                    // Stash tiles for distribution
                    stash includes: 'chunk-0.jpg', name: 'tile-TL' // Top-Left
                    stash includes: 'chunk-1.jpg', name: 'tile-TR' // Top-Right
                    stash includes: 'chunk-2.jpg', name: 'tile-BL' // Bottom-Left
                    stash includes: 'chunk-3.jpg', name: 'tile-BR' // Bottom-Right
                }
            }
        }
        
        stage('Distributed Matrix Processing') {
            parallel {
                // --- SLAVE 1: DIAGONAL 1 (Top-Left & Bottom-Right) ---
                stage('Diagonal 1 (Slave 1)') {
                    agent { label 'slave-1' } 
                    steps {
                        script {
                            // 1. Get Tiles
                            unstash 'tile-TL'
                            unstash 'tile-BR'
                            
                            // 2. Process: "Filter them"
                            echo "Slave 1: Processing Diagonal 1"
                            sh 'convert chunk-0.jpg -charcoal 2 processed_TL.jpg'
                            sh 'convert chunk-3.jpg -colorspace Gray -edge 2 processed_BR.jpg'
                            
                            // 3. Return Results
                            stash includes: 'processed_TL.jpg', name: 'result-TL'
                            stash includes: 'processed_BR.jpg', name: 'result-BR'
                        }
                    }
                }
                
                // --- SLAVE 2: DIAGONAL 2 (Top-Right & Bottom-Left) ---
                stage('Diagonal 2 (Slave 2)') {
                    agent { label 'slave-2' } 
                    steps {
                        script {
                            // 1. Get Tiles
                            unstash 'tile-TR'
                            unstash 'tile-BL'
                            
                            // 2. Process: "Filter them"
                            echo "Slave 2: Processing Diagonal 2"
                            sh 'convert chunk-1.jpg -negate -edge 1 processed_TR.jpg'
                            sh 'convert chunk-2.jpg -sepia-tone 80% processed_BL.jpg'
                            
                            // 3. Return Results
                            stash includes: 'processed_TR.jpg', name: 'result-TR'
                            stash includes: 'processed_BL.jpg', name: 'result-BL'
                        }
                    }
                }
            }
        }
        
        stage('Matrix Assembly (Master)') {
            agent { label 'built-in' }
            steps {
                script {
                    echo "Retrieving 4 Tiles..."
                    unstash 'result-TL'
                    unstash 'result-TR'
                    unstash 'result-BL'
                    unstash 'result-BR'
                    
                    echo "Stitching 2x2 Grid..."
                    // Step 1: Stitch Top Row (Left + Right)
                    sh 'convert +append processed_TL.jpg processed_TR.jpg row_top.jpg'
                    
                    // Step 2: Stitch Bottom Row (Left + Right)
                    sh 'convert +append processed_BL.jpg processed_BR.jpg row_bottom.jpg'
                    
                    // Step 3: Stitch Rows Vertically (Top / Bottom)
                    sh 'convert -append row_top.jpg row_bottom.jpg final_checkerboard.jpg'
                    
                    // Publish
                    sh 'cp final_checkerboard.jpg /var/lib/jenkins/userContent/checker_result.jpg'
                    
                    echo "SUCCESS! Check the Matrix here: ${JENKINS_URL}userContent/checker_result.jpg"
                }
            }
        }
    }
}
