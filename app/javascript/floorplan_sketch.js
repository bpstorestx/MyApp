// floorplan_sketch.js - Handles the sketch functionality for floorplans

// Listen for either Turbolinks load or DOMContentLoaded events
document.addEventListener('turbolinks:load', () => {
  initializeCanvas();
});

document.addEventListener('DOMContentLoaded', () => {
  initializeCanvas();
});

// Initialize Fabric on a <canvas> element
function initializeCanvas() {
  console.log('Checking for canvas element...');
  
  // Find the canvas element for sketching
  const canvasEl = document.getElementById('floorplan-canvas');
  
  if (!canvasEl) {
    console.log('No canvas element found on this page');
    return;
  }
  
  console.log('Canvas element found, initializing Fabric.js...');
  
  // Make sure Fabric.js is loaded
  if (typeof fabric === 'undefined') {
    console.error('Fabric.js is not loaded. Please check the script inclusion.');
    return;
  }
  
  // Create Fabric canvas and enable freehand drawing
  const canvas = new fabric.Canvas('floorplan-canvas', {
    isDrawingMode: true
  });
  
  // Add a test rectangle to confirm Fabric is working
  canvas.add(new fabric.Rect({
    left: 50, top: 50, width: 100, height: 80, fill: 'rgba(200,0,0,0.3)', selectable: false
  }));
  
  // Set brush defaults
  canvas.freeDrawingBrush.width = 3;
  canvas.freeDrawingBrush.color = '#000000';
  
  console.log('Fabric.js canvas initialized successfully');
  
  // Check if we should load a background image
  const originalImg = document.getElementById('original-img');
  if (originalImg && originalImg.complete) {
    loadBackgroundImage(canvas, originalImg);
  } else if (originalImg) {
    originalImg.onload = function() {
      loadBackgroundImage(canvas, originalImg);
    };
  }
}

// Load the original image as the canvas background
function loadBackgroundImage(canvas, imgElement) {
  console.log('Loading background image...');
  
  fabric.Image.fromURL(imgElement.src, img => {
    // Scale the image to fit the canvas
    const canvasWidth = canvas.getWidth();
    const canvasHeight = canvas.getHeight();
    
    const scaleX = canvasWidth / img.width;
    const scaleY = canvasHeight / img.height;
    const scale = Math.min(scaleX, scaleY);
    
    img.scale(scale);
    
    // Set as background and render
    canvas.setBackgroundImage(img, canvas.renderAll.bind(canvas));
    console.log('Background image loaded successfully');
  }, { crossOrigin: 'anonymous' });
} 