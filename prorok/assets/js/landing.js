(function () {
  const scene = document.querySelector('.scene');
  const bg = document.querySelector('.scene-bg');
  if (!scene || !bg) return;

  scene.addEventListener('mousemove', function (e) {
    const rect = scene.getBoundingClientRect();
    const x = (e.clientX - rect.left) / rect.width - 0.5;
    const y = (e.clientY - rect.top) / rect.height - 0.5;
    bg.style.transform = 'translate(' + (x * -6) + 'px, ' + (y * -6) + 'px)';
  });

  scene.addEventListener('mouseleave', function () {
    bg.style.transform = 'scale(1.06) translate(0px, 0px)';
  });
})();
