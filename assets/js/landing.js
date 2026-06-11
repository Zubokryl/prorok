(function () {
  const scene = document.querySelector('.scene');
  const bgImg = document.querySelector('.bg-img');
  if (!scene || !bgImg) return;

  const strength = 10; /* max parallax offset in px */

  scene.addEventListener('mousemove', function (e) {
    const rect = scene.getBoundingClientRect();
    const nx = (e.clientX - rect.left) / rect.width  - 0.5;
    const ny = (e.clientY - rect.top)  / rect.height - 0.5;
    bgImg.style.transform =
      'translate3d(' + (nx * -strength) + 'px, ' + (ny * -strength) + 'px, 0)';
  }, { passive: true });

  scene.addEventListener('mouseleave', function () {
    bgImg.style.transform = 'translate3d(0px, 0px, 0)';
  });
})();
