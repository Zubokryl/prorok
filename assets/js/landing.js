(function () {
  const scene = document.querySelector('.scene');
  const bgImg = document.querySelector('.bg-img');
  if (!scene || !bgImg) return;

  let targetX = 0;
  let targetY = 0;
  let currentX = 0;
  let currentY = 0;
  let animating = false;
  const strength = 8;   /* max parallax offset in px */
  const ease = 0.06;    /* lerp factor — lower = smoother */

  function tick() {
    currentX += (targetX - currentX) * ease;
    currentY += (targetY - currentY) * ease;
    bgImg.style.transform =
      'translate(' + currentX.toFixed(2) + 'px, ' + currentY.toFixed(2) + 'px)';

    if (Math.abs(targetX - currentX) > 0.05 ||
        Math.abs(targetY - currentY) > 0.05) {
      requestAnimationFrame(tick);
    } else {
      animating = false;
      bgImg.style.transform =
        'translate(' + targetX + 'px, ' + targetY + 'px)';
    }
  }

  function startAnim() {
    if (!animating) {
      animating = true;
      requestAnimationFrame(tick);
    }
  }

  scene.addEventListener('mousemove', function (e) {
    const rect = scene.getBoundingClientRect();
    const nx = (e.clientX - rect.left) / rect.width  - 0.5;
    const ny = (e.clientY - rect.top)  / rect.height - 0.5;
    targetX = nx * -strength;
    targetY = ny * -strength;
    startAnim();
  });

  scene.addEventListener('mouseleave', function () {
    targetX = 0;
    targetY = 0;
    startAnim();
  });
})();
