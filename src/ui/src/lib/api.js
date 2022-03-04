const FIREBASE_DOMAIN = 'http://localhost:9098';

export async function getAllQuotes() {
  const response = await fetch(`${FIREBASE_DOMAIN}/quotes.json`);
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Could not fetch quotes.');
  }

  const transformedQuotes = [];

  for (const key in data) {
    const quoteObj = {
      id: key,
      ...data[key],
    };

    transformedQuotes.push(quoteObj);
  }

  return transformedQuotes;
}

export async function getHomePage() {
  const response = await fetch(`${FIREBASE_DOMAIN}`, {credentials: "include"});
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Could not fetch quotes.');
  }

  return data;
}

export async function getSingleProduct(productId) {
  const response = await fetch(`${FIREBASE_DOMAIN}/product/${productId}`, {credentials: "include"});
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Could not fetch quote.');
  }

  return data;
}


export async function addProductToCart(requestData) {
  const response = await fetch(`${FIREBASE_DOMAIN}/cart/`, {
    method: 'POST',
    body: JSON.stringify(requestData),
    headers: {
      'Content-Type': 'application/json',
    },
    credentials: "include"
  });
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Could not add comment.');
  }

  return { };
}

export async function getCartPage() {
  const response = await fetch(`${FIREBASE_DOMAIN}/cart`, {credentials: "include"});
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Could not fetch quotes.');
  }

  return data;
}

export async function checkout(requestData) {
  const response = await fetch(`${FIREBASE_DOMAIN}/cart/checkout`, {
    method: 'POST',
    body: JSON.stringify(requestData),
    headers: {
      'Content-Type': 'application/json',
    },
    credentials: "include"
  });
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Could not add comment.');
  }

  return data;
}

export async function getMetadata() {
  const response = await fetch(`${FIREBASE_DOMAIN}/metadata`, {credentials: "include"});
  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.message || 'Could not fetch quotes.');
  }

  return data;
}
