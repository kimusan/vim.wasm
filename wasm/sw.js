function responseAfter(ms) {
    const prev = Date.now();
    return new Promise(resolve => {
        setTimeout(() => {
            console.log('Sleep', Date.now() - prev, 'ms');
            resolve(new Response('wake up!'));
        }, ms);
    });
}

self.addEventListener('fetch', event => {
    if (!event.request.url.endsWith('sleep-frame.txt')) {
        return;
    }
    event.respondWith(responseAfter(20));
});
