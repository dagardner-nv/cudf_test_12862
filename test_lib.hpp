#include <cudf/io/csv.hpp>
#include <cudf/io/types.hpp>

#include <string>

cudf::io::table_with_metadata load_table_from_csv(const std::string& filename);