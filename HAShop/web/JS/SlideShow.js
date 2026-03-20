let slideIndex = 0;

function runBannerSlideShow(){
  const slides = document.querySelectorAll(".slideshow .slide");
  if(!slides.length) return;

  slides.forEach(s => s.classList.remove("active"));

  slideIndex++;
  if(slideIndex > slides.length) slideIndex = 1;

  slides[slideIndex - 1].classList.add("active");

  setTimeout(runBannerSlideShow, 4000); // 2 giây
}

document.addEventListener("DOMContentLoaded", runBannerSlideShow);
