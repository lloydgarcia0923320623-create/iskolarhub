const menuButton = document.querySelector(".menu-toggle");
const navLinks = document.querySelector(".nav-links");

const revealTargets = document.querySelectorAll(
  ".intro-grid, .word-strip, .section-heading, .feature-card, .journey-heading, .journey-steps li, .stack-card, .honesty-card, .closing-card",
);

if (
  "IntersectionObserver" in window &&
  !window.matchMedia("(prefers-reduced-motion: reduce)").matches
) {
  document.body.classList.add("motion-ready");

  const revealObserver = new IntersectionObserver(
    (entries, observer) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          entry.target.classList.add("is-visible");
          observer.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.14, rootMargin: "0px 0px -38px 0px" },
  );

  revealTargets.forEach((target) => {
    target.classList.add("reveal-on-scroll");
    revealObserver.observe(target);
  });
}

const header = document.querySelector(".site-header");

if (header) {
  const progress = document.createElement("div");
  progress.className = "scroll-progress";
  progress.setAttribute("aria-hidden", "true");
  progress.innerHTML = "<span></span>";
  header.append(progress);

  const progressBar = progress.firstElementChild;
  let progressFrame = 0;

  const updateProgress = () => {
    const scrollableHeight =
      document.documentElement.scrollHeight - window.innerHeight;
    const amount =
      scrollableHeight > 0 ? window.scrollY / scrollableHeight : 0;

    progressBar.style.transform = `scaleX(${Math.min(amount, 1)})`;
    progressFrame = 0;
  };

  window.addEventListener(
    "scroll",
    () => {
      if (!progressFrame) {
        progressFrame = window.requestAnimationFrame(updateProgress);
      }
    },
    { passive: true },
  );

  updateProgress();
}

if (menuButton && navLinks) {
  menuButton.addEventListener("click", () => {
    const isOpen = menuButton.getAttribute("aria-expanded") === "true";
    menuButton.setAttribute("aria-expanded", String(!isOpen));
    menuButton.setAttribute(
      "aria-label",
      isOpen ? "Open navigation menu" : "Close navigation menu",
    );
    navLinks.classList.toggle("is-open", !isOpen);
  });

  navLinks.addEventListener("click", (event) => {
    if (event.target instanceof HTMLAnchorElement) {
      menuButton.setAttribute("aria-expanded", "false");
      menuButton.setAttribute("aria-label", "Open navigation menu");
      navLinks.classList.remove("is-open");
    }
  });
}

document.querySelectorAll(".feature-card").forEach((card) => {
  card.addEventListener("pointermove", (event) => {
    if (event.pointerType === "touch") {
      return;
    }

    const bounds = card.getBoundingClientRect();
    const x = (event.clientX - bounds.left) / bounds.width;
    const y = (event.clientY - bounds.top) / bounds.height;

    card.style.setProperty("--pointer-x", `${x * 100}%`);
    card.style.setProperty("--pointer-y", `${y * 100}%`);
    card.style.setProperty("--tilt-x", `${((0.5 - y) * 4).toFixed(2)}deg`);
    card.style.setProperty("--tilt-y", `${((x - 0.5) * 4).toFixed(2)}deg`);
  });

  card.addEventListener("pointerleave", () => {
    card.style.removeProperty("--tilt-x");
    card.style.removeProperty("--tilt-y");
  });
});
