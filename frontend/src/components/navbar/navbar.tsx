import { useEffect, useState } from "react";
import "./nav.css";

export default function NavBar() {
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onKey = (e) => e.key === "Escape" && setOpen(false);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => (document.body.style.overflow = "");
  }, [open]);

  return (
    <>
      <header className="gits-nav">
        <div className="gits-nav__inner">
          <a className="gits-brand" href="/">
            <img className="logo logo--md" src="/logo.svg" alt="SOD SANCTUM" />
            <span className="gits-brand__text">
              SOD<span className="gits-dot">•</span>SANCTUM
            </span>
          </a>

          <nav className="gits-links" aria-label="Primary">
            <a className="gits-link" href="#protocol">Protocol</a>
            <a className="gits-link" href="#privacy">Privacy</a>
            <a className="gits-link" href="#rewards">Rewards</a>
            <a className="gits-link" href="#docs">Docs</a>
          </nav>

          <div className="gits-actions">
            <a className="gits-cta" href="#app">Launch App</a>

            <button
              className="gits-burger"
              type="button"
              aria-label="Open menu"
              aria-expanded={open}
              onClick={() => setOpen((v) => !v)}
            >
              <span />
              <span />
              <span />
            </button>
          </div>
        </div>

        <div className="gits-hairline" />
      </header>

      {/* Mobile overlay */}
      <div className={`gits-overlay ${open ? "is-open" : ""}`} onClick={() => setOpen(false)}>
        <div className="gits-drawer" onClick={(e) => e.stopPropagation()}>
          <div className="gits-drawer__top">
            <span className="gits-drawer__title">MENU</span>
            <button className="gits-close" onClick={() => setOpen(false)} aria-label="Close menu">
              ✕
            </button>
          </div>

          <a className="gits-drawer__link" href="#protocol" onClick={() => setOpen(false)}>Protocol</a>
          <a className="gits-drawer__link" href="#privacy" onClick={() => setOpen(false)}>Privacy</a>
          <a className="gits-drawer__link" href="#rewards" onClick={() => setOpen(false)}>Rewards</a>
          <a className="gits-drawer__link" href="#docs" onClick={() => setOpen(false)}>Docs</a>

          <a className="gits-drawer__cta" href="#app" onClick={() => setOpen(false)}>
            Launch App
          </a>
        </div>
      </div>
    </>
  );
}
