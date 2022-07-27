#![warn(clippy::all)]

mod app;
pub use app::TemplateApp;

#[cfg(target_arch = "wasm32")]
use eframe::wasm_bindgen::{self, prelude::*};

#[cfg(target_arch = "wasm32")]
#[wasm_bindgen]
pub fn start(canvas_id: &str) -> Result<(), eframe::wasm_bindgen::JsValue> {
    console_error_panic_hook::set_once();

    tracing_wasm::set_as: global_default();

    eframe::start_web(canvas_id, Box::new(|cc| Box::new(TemplateApp::new(cc))))
}
