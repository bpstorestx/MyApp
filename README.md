# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## Local Development
* Server is now running on localhost:3000

## Heroku Deployment
* Live application: https://fierce-mesa-04934-8494e4472c2c.herokuapp.com/

## Floorplan Generation Features

### Prompting Strategies

The application offers three different generation approaches when uploading floorplans:

1. **Generate Immediately** - Quick generation with standard prompting
   * Uses our default AI prompt to create a professional office layout
   * Creates a clean, top-down architectural image with open common areas and perimeter offices
   * Maintains the original outline with the same windows and entry points
   * Blueprint-like, lease-ready style

2. **Add Custom Instructions** - Standard generation enhanced with user requirements
   * Allows users to specify detailed requirements before generation
   * Combines the standard architectural prompt with custom user instructions
   * Perfect for specific office needs without requiring sketching skills
   * Examples: "Need 6 private offices, large conference room, reception area"

3. **Sketch & Customize** - Advanced design with drawing tools and custom instructions
   * Positions the AI as a master architect specializing in modern efficient office space design
   * Users can draw RED modifications directly on their floorplan
   * Supports both sketched annotations AND custom text instructions
   * Preserves exterior walls and doors while incorporating user modifications
   * Most comprehensive option for detailed customization

### Custom Prompt Feature

Both the "Add Custom Instructions" and "Sketch & Customize" options support detailed custom prompts:
* Saved to the database and displayed on the results page
* Integrated into the AI generation process
* Examples: room counts, special requirements, accessibility needs, etc.
* Enhances rather than replaces the base architectural prompts

To use Custom Instructions:
1. Upload a floorplan image
2. Select "Add Custom Instructions" or "Sketch & Customize"
3. Enter your specific requirements in the text area
4. For sketching: Use the drawing tools to add visual modifications
5. Generate your customized floorplan
