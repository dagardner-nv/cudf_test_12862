#include "test_lib.hpp"

#include <pybind11/embed.h>

#include <iostream>

#include "./build/cudf_helpers_api.h"

int main() {
  std::cout << "Hello World" << std::endl;
  auto table = load_table_from_csv("./test.csv");

  std::cout << "Initializing Python" << std::endl;
  pybind11::initialize_interpreter();
  pybind11::gil_scoped_acquire gil;

  std::cout << "Importing cudf" << std::endl;
  auto cudf_mod = pybind11::module_::import("cudf");
  pybind11::print(cudf_mod);

  if (import_cudf_helpers() != 0)
  {
    pybind11::error_already_set ex;
    std::cout << "Failed to load cudf_helpers: " << ex.what() << std::endl;
  }

  auto df = pybind11::reinterpret_steal<pybind11::object>((PyObject*)make_table_from_table_with_metadata(std::move(table)));
  pybind11::print(df);

  return 0;
}
