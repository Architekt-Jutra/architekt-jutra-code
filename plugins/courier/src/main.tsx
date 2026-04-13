import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { CourierDashboard } from "./pages/CourierDashboard";
import { ProductDeliveryTab } from "./pages/ProductDeliveryTab";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<CourierDashboard />} />
        <Route path="/product-delivery" element={<ProductDeliveryTab />} />
      </Routes>
    </BrowserRouter>
  </StrictMode>,
);
