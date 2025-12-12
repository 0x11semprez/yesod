import { useEffect } from "react";
import Logo from "../logo/Logo";
import ButtonW from "../wallet/Buttonw";
import "./nav.css";

const NavBar = () => {
  // Inject FX spans inside thirdweb button (robust)
  useEffect(() => {
    const root = document.querySelector(".gits-connectWrap");
    if (!root) return;

    const inject = () => {
      const btn = root.querySelector("button");
      if (!btn) return;

      // avoid duplicates
      if (!btn.querySelector(".fx-radar")) {
        const s = document.createElement("span");
        s.className = "fx-radar";
        s.setAttribute("aria-hidden", "true");
        btn.appendChild(s);
      }
      if (!btn.querySelector(".fx-grain")) {
        const s = document.createElement("span");
        s.className = "fx-grain";
        s.setAttribute("aria-hidden", "true");
        btn.appendChild(s);
      }
    };

    inject();

    // If thirdweb re-renders / replaces DOM
    const obs = new MutationObserver(inject);
    obs.observe(root, { childList: true, subtree: true });

    return () => obs.disconnect();
  }, []);

  return (
    <header className="gits-nav">
      <div className="gits-nav__inner">
        <a className="gits-brand" href="/" aria-label="Home">
          <span className="gits-brand__text">
            <Logo />
            <span className="gits-dot" aria-hidden="true" />
          </span>
        </a>

        <nav className="gits-links" aria-label="Primary navigation">
          <a className="gits-link" href="#protocol">Protocol</a>
          <a className="gits-link" href="#privacy">Privacy</a>
          <a className="gits-link" href="#rewards">Rewards</a>
          <a className="gits-link" href="#docs">Docs</a>
        </nav>

        <div className="gits-actions">
          <div className="gits-connectWrap">
            <ButtonW />
          </div>
        </div>
      </div>
    </header>
  );
};

export default NavBar;
