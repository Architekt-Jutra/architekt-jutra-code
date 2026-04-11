import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { ProductWeightTab } from "./pages/ProductWeightTab";
import { ProductWeightBadge } from "./pages/ProductWeightBadge";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/product-weight" element={<ProductWeightTab />} />
        <Route path="/product-weight-badge" element={<ProductWeightBadge />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
);
