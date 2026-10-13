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

const phoneTabs = Array.from(document.querySelectorAll(".phone-tabbar [role='tab']"));

if (phoneTabs.length > 0) {
  const activatePhoneTab = (tab) => {
    phoneTabs.forEach((item) => {
      const selected = item === tab;
      item.setAttribute("aria-selected", String(selected));
      item.tabIndex = selected ? 0 : -1;
      item.classList.toggle("tab-active", selected);

      const panel = document.getElementById(item.getAttribute("aria-controls"));
      if (panel) {
        panel.hidden = !selected;
      }
    });
  };

  phoneTabs.forEach((tab, index) => {
    tab.addEventListener("click", () => activatePhoneTab(tab));
    tab.addEventListener("keydown", (event) => {
      let nextIndex;
      if (event.key === "ArrowRight") {
        nextIndex = (index + 1) % phoneTabs.length;
      } else if (event.key === "ArrowLeft") {
        nextIndex = (index - 1 + phoneTabs.length) % phoneTabs.length;
      } else if (event.key === "Home") {
        nextIndex = 0;
      } else if (event.key === "End") {
        nextIndex = phoneTabs.length - 1;
      } else {
        return;
      }

      event.preventDefault();
      phoneTabs[nextIndex].focus();
      activatePhoneTab(phoneTabs[nextIndex]);
    });
  });
}

const savedScholarships = new Map();
const savedList = document.querySelector(".saved-list");
const savedEmpty = document.querySelector(".saved-empty");
const phoneStatusMessage = document.querySelector(".phone-status-message");

const updateSavedScholarships = () => {
  document.querySelectorAll(".opportunity-card[data-scholarship-id]").forEach((card) => {
    const id = card.dataset.scholarshipId;
    const isSaved = savedScholarships.has(id);
    const button = card.querySelector(".bookmark");

    if (button) {
      button.setAttribute("aria-pressed", String(isSaved));
      button.setAttribute(
        "aria-label",
        `${isSaved ? "Remove" : "Save"} ${card.dataset.scholarshipTitle} ${isSaved ? "from" : "to"} saved`,
      );
      button.textContent = isSaved ? "♥" : "♡";
    }
  });

  if (!savedList || !savedEmpty) {
    return;
  }

  savedList.replaceChildren();
  savedEmpty.hidden = savedScholarships.size > 0;

  savedScholarships.forEach((scholarship) => {
    const card = document.createElement("article");
    card.className = "saved-scholarship";
    const title = document.createElement("strong");
    title.textContent = scholarship.title;
    const description = document.createElement("span");
    description.textContent = scholarship.description;
    card.append(title, description);
    savedList.append(card);
  });
};

document.querySelectorAll(".bookmark").forEach((button) => {
  button.addEventListener("click", () => {
    const card = button.closest(".opportunity-card");
    const id = card?.dataset.scholarshipId;
    const title = card?.dataset.scholarshipTitle;

    if (!id || !title) {
      return;
    }

    if (savedScholarships.has(id)) {
      savedScholarships.delete(id);
      if (phoneStatusMessage) {
        phoneStatusMessage.textContent = `${title} removed from saved scholarships.`;
      }
    } else {
      savedScholarships.set(id, {
        title,
        description: card.dataset.scholarshipDescription ?? "",
      });
      if (phoneStatusMessage) {
        phoneStatusMessage.textContent = `${title} added to saved scholarships.`;
      }
    }

    updateSavedScholarships();
  });
});

document.querySelectorAll(".scholarship-search").forEach((input) => {
  input.addEventListener("input", () => {
    const query = input.value.trim().toLocaleLowerCase();
    const cards = document.querySelectorAll(".scholarship-list .opportunity-card");
    let visibleCount = 0;

    cards.forEach((card) => {
      const matches = card.textContent.toLocaleLowerCase().includes(query);
      card.hidden = !matches;
      visibleCount += Number(matches);
    });

    const emptyState = document.querySelector(".search-empty");
    if (emptyState) {
      emptyState.hidden = visibleCount > 0;
    }
  });
});
