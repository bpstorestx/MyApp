const redis = require('redis');
const { promisify } = require('util');

// The Redis URL from Heroku
const redisUrl = process.env.REDIS_URL || 'rediss://p5d8f287a9e023c96ba7e7d2ae233fcbbf55b6e022aa3ddb43e15a56e97e93ff2@ec2-3-82-214-32.compute-1.amazonaws.com:16470';

// Create Redis client with SSL options for rediss:// URLs
const redisOptions = {
  url: redisUrl,
  socket: {}
};

if (redisUrl.startsWith('rediss://')) {
  redisOptions.socket.tls = true;
  redisOptions.socket.rejectUnauthorized = false;
}

console.log('Connecting to Redis with options:', JSON.stringify(redisOptions, null, 2));

// Create the client
const client = redis.createClient(redisOptions);

// Set up error handler
client.on('error', (err) => {
  console.error('Redis Client Error:', err);
  process.exit(1);
});

// Connect and test
async function testRedis() {
  try {
    await client.connect();
    console.log('Connected to Redis successfully');
    
    const pingResult = await client.ping();
    console.log('Redis PING result:', pingResult);
    
    await client.quit();
    console.log('Redis connection closed');
  } catch (err) {
    console.error('Error connecting to Redis:', err);
    process.exit(1);
  }
}

testRedis(); 