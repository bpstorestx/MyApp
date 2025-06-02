// floorplan_canvas.js
// Try multiple event listeners to ensure the script runs
document.addEventListener('DOMContentLoaded', initCanvas);
document.addEventListener('turbo:load', initCanvas);

// Main initialization function
function initCanvas() {
  console.log('Initializing canvas function called');
  
  const canvasElement = document.getElementById('floorplan-canvas');
  const originalImgElement = document.getElementById('original-img');
  const statusMessage = document.getElementById('status-message');

  if (!canvasElement) {
    console.error('Canvas element not found');
    return;
  }

  if (!originalImgElement) {
    console.error('Original image element not found');
    return;
  }

  console.log('Canvas and image elements found, initializing Fabric.js canvas');
  
  // Show status message
  function showStatus(message, isError = false) {
    if (!statusMessage) return;
    
    statusMessage.textContent = message;
    statusMessage.style.display = 'block';
    statusMessage.style.backgroundColor = isError ? '#f8d7da' : '#f8f9fa';
    statusMessage.style.color = isError ? '#721c24' : '#212529';
    console.log('Status:', message);
    
    if (!isError) {
      setTimeout(() => {
        statusMessage.style.display = 'none';
      }, 3000);
    }
  }

  // Make sure Fabric.js is loaded
  if (typeof fabric === 'undefined') {
    console.error('Fabric.js is not loaded');
    showStatus('Error: Fabric.js library not loaded', true);
    return;
  }

  try {
    // Create Fabric canvas
    window.canvas = new fabric.Canvas('floorplan-canvas', {
      isDrawingMode: true,
      backgroundColor: 'white'
    });

    const canvas = window.canvas;

    // Set initial canvas size
    canvas.setWidth(canvasElement.getAttribute('width') || 800);
    canvas.setHeight(canvasElement.getAttribute('height') || 600);
    canvas.renderAll();

    // Draw a blue rectangle to verify canvas is working
    const rect = new fabric.Rect({
      left: 10,
      top: 10,
      width: 50,
      height: 50,
      fill: 'blue'
    });
    canvas.add(rect);
    canvas.renderAll();
    
    console.log('Blue rectangle added to canvas to verify it works');

    // Now load the image - first ensure the image is fully loaded
    if (!originalImgElement.complete) {
      showStatus('Waiting for image to load...');
      originalImgElement.onload = function() {
        loadImageToCanvas(canvas, originalImgElement);
      };
    } else {
      loadImageToCanvas(canvas, originalImgElement);
    }

    // Set up tool buttons
    setupToolButtons(canvas);
    
  } catch (error) {
    console.error('Error initializing Fabric.js canvas:', error);
    showStatus('Error initializing canvas: ' + error.message, true);
  }
}

// Function to load image to canvas
function loadImageToCanvas(canvas, imgElement) {
  try {
    console.log('Loading image as background, image src:', imgElement.src);
    
    fabric.Image.fromURL(imgElement.src, img => {
      try {
        console.log('Image loaded successfully, dimensions:', img.width, 'x', img.height);
        
        // Remove the test rectangle
        canvas.clear();
        canvas.backgroundColor = 'white';
        
        img.set({
          left: 0,
          top: 0,
          selectable: false,
          evented: false
        });

        // Scale the image to fit the canvas
        const scaleX = canvas.getWidth() / img.width;
        const scaleY = canvas.getHeight() / img.height;
        const scale = Math.min(scaleX, scaleY);
        
        img.scale(scale);
        console.log('Image scaled to fit canvas, scale factor:', scale);

        // Set as background and render
        canvas.setBackgroundImage(img, canvas.renderAll.bind(canvas));
        console.log('Background image set successfully');
        
        document.getElementById('status-message').textContent = 'Canvas ready for annotation';
        document.getElementById('status-message').style.display = 'block';
      } catch (error) {
        console.error('Error setting up background image:', error);
        document.getElementById('status-message').textContent = 'Error setting up background image: ' + error.message;
        document.getElementById('status-message').style.display = 'block';
        document.getElementById('status-message').style.backgroundColor = '#f8d7da';
        document.getElementById('status-message').style.color = '#721c24';
      }
    }, {
      crossOrigin: 'anonymous'
    });
  } catch (error) {
    console.error('Error in loadImageToCanvas:', error);
  }
}

// Set up all tool buttons and controls
function setupToolButtons(canvas) {
  // Configure drawing brush
  canvas.freeDrawingBrush.width = 5;
  canvas.freeDrawingBrush.color = '#ff0000';

  // Get tool elements
  const penTool = document.getElementById('pen-tool');
  const eraserTool = document.getElementById('eraser-tool');
  const textTool = document.getElementById('text-tool');
  const clearBtn = document.getElementById('clear-btn');
  const saveBtn = document.getElementById('save-btn');
  const colorPicker = document.getElementById('color-picker');
  const sizeSlider = document.getElementById('size-slider');
  const sizeValue = document.getElementById('size-value');

  // Helper function to set active button
  function setActiveButton(button) {
    if (!button) return;
    
    const toolButtons = document.querySelectorAll('.tool-btn');
    toolButtons.forEach(btn => {
      btn.classList.remove('active');
    });
    button.classList.add('active');
  }

  // Pen tool
  if (penTool) {
    penTool.addEventListener('click', () => {
      canvas.isDrawingMode = true;
      canvas.freeDrawingBrush.color = colorPicker ? colorPicker.value : '#ff0000';
      setActiveButton(penTool);
      console.log('Pen tool selected');
    });
  }

  // Eraser tool
  if (eraserTool) {
    eraserTool.addEventListener('click', () => {
      canvas.isDrawingMode = true;
      canvas.freeDrawingBrush.color = '#ffffff'; // White for eraser
      setActiveButton(eraserTool);
      console.log('Eraser tool selected');
    });
  }

  // Text tool
  if (textTool) {
    textTool.addEventListener('click', () => {
      const text = prompt('Enter text:');
      if (text) {
        canvas.isDrawingMode = false;
        const textObj = new fabric.Text(text, {
          left: canvas.getWidth() / 2,
          top: canvas.getHeight() / 2,
          fill: colorPicker ? colorPicker.value : '#ff0000',
          fontSize: sizeSlider ? parseInt(sizeSlider.value) * 3 : 20
        });
        canvas.add(textObj);
        canvas.renderAll();
        console.log('Text added');
      }
      
      // Switch back to pen tool
      canvas.isDrawingMode = true;
      if (penTool) setActiveButton(penTool);
    });
  }

  // Color picker
  if (colorPicker) {
    colorPicker.addEventListener('input', () => {
      if (eraserTool && eraserTool.classList.contains('active')) {
        // Don't change eraser color
        return;
      }
      canvas.freeDrawingBrush.color = colorPicker.value;
    });
  }

  // Size slider
  if (sizeSlider && sizeValue) {
    sizeSlider.addEventListener('input', () => {
      const size = parseInt(sizeSlider.value);
      canvas.freeDrawingBrush.width = size;
      sizeValue.textContent = size;
    });
  }

  // Clear button
  if (clearBtn) {
    clearBtn.addEventListener('click', () => {
      if (confirm('Are you sure you want to clear all annotations?')) {
        canvas.clear();
        canvas.backgroundColor = 'white';
        
        // Restore the background image
        if (canvas.backgroundImage) {
          canvas.setBackgroundImage(canvas.backgroundImage, canvas.renderAll.bind(canvas));
        }
        
        console.log('Canvas cleared');
      }
    });
  }

  // Save button
  if (saveBtn) {
    saveBtn.addEventListener('click', () => {
      try {
        console.log('Saving annotation...');
        
        // Get the canvas data URL
        const imageData = canvas.toDataURL('image/png');
        
        // Get the CSRF token from the meta tag
        const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
        
        // Get the save URL from the save button's data attribute
        const saveUrl = saveBtn.getAttribute('data-save-url');
        
        console.log('Sending data to server at URL:', saveUrl);
        
        // Send to server
        fetch(saveUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken
          },
          body: JSON.stringify({
            canvas_data: imageData
          })
        })
        .then(response => {
          console.log('Server response received, status:', response.status);
          return response.json();
        })
        .then(data => {
          console.log('Server response data:', data);
          if (data.success) {
            document.getElementById('status-message').textContent = 'Annotation saved successfully! Redirecting...';
            document.getElementById('status-message').style.display = 'block';
            
            setTimeout(() => {
              window.location.href = data.redirect_url || saveBtn.getAttribute('data-redirect-url');
            }, 1000);
          } else {
            document.getElementById('status-message').textContent = 'Error saving annotation: ' + (data.message || 'Unknown error');
            document.getElementById('status-message').style.display = 'block';
            document.getElementById('status-message').style.backgroundColor = '#f8d7da';
            document.getElementById('status-message').style.color = '#721c24';
          }
        })
        .catch(error => {
          console.error('Error saving annotation:', error);
          document.getElementById('status-message').textContent = 'Error saving annotation: ' + error.message;
          document.getElementById('status-message').style.display = 'block';
          document.getElementById('status-message').style.backgroundColor = '#f8d7da';
          document.getElementById('status-message').style.color = '#721c24';
        });
      } catch (error) {
        console.error('Error generating image:', error);
        document.getElementById('status-message').textContent = 'Error generating image: ' + error.message;
        document.getElementById('status-message').style.display = 'block';
        document.getElementById('status-message').style.backgroundColor = '#f8d7da';
        document.getElementById('status-message').style.color = '#721c24';
      }
    });
  }

  // Set initial active tool
  if (penTool) {
    setActiveButton(penTool);
  }
} 