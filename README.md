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

The application uses two different prompting strategies when generating floorplans with OpenAI:

1. **Standard Prompting** - Used when a floorplan is uploaded without sketching
   * Creates a clean, top-down architectural image of a professional office layout
   * Includes a large open common area in the center and private offices along the perimeter
   * Maintains the original outline with the same windows and entry points
   * Blueprint-like, lease-ready style

2. **Sketched Prompting** - Used when the "Sketch on your floorplan for CAD-style architectural design" checkbox is selected
   * Positions the AI as a master architect specializing in modern efficient office space design
   * Emphasizes workspace flow with doors and open layout for efficiency
   * Frames the AI as advising a commercial real estate client
   * Preserves exterior walls and doors
   * Uses the client's sketched lines and text notes to generate an updated floorplan

To use Sketched Prompting:
1. Upload a floorplan image
2. Check the "Sketch on your floorplan for CAD-style architectural design (Sketched Prompting)" option
3. Use the drawing tools to sketch your desired floor plan layout
4. Save the sketch to generate the CAD-style architectural floorplan
