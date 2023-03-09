# SPDX-FileCopyrightText: Copyright (c) 2021-2023, NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import cudf

from libcpp.memory cimport make_shared
from libcpp.memory cimport make_unique
from libcpp.memory cimport shared_ptr
from libcpp.memory cimport unique_ptr
from libcpp.string cimport string
from libcpp.utility cimport move
from libcpp.vector cimport vector

from cudf._lib.column cimport Column
from cudf._lib.cpp.column.column_view cimport column_view
from cudf._lib.cpp.io.types cimport column_name_info
from cudf._lib.cpp.io.types cimport table_metadata
from cudf._lib.cpp.io.types cimport table_with_metadata
from cudf._lib.cpp.table.table_view cimport table_view
from cudf._lib.utils cimport data_from_table_view
from cudf._lib.utils cimport data_from_unique_ptr
from cudf._lib.utils cimport get_column_names
from cudf._lib.utils cimport table_view_from_table

cdef public api:
    object make_table_from_table_with_metadata(table_with_metadata table):

        index_names = None
        column_names = []
        index_col_count = 0

        # Need to support both column_names and schema_info
        if (table.metadata.column_names.size() > 0):
            column_names = [x.decode() for x in table.metadata.column_names[index_col_count:]]
        elif (table.metadata.schema_info.size() > 0):
            for i in range(index_col_count, table.metadata.schema_info.size()):
                column_names.append(table.metadata.schema_info[i].name.decode())

        data, index = data_from_unique_ptr(move(table.tbl), column_names=column_names, index_names=index_names)

        return cudf.DataFrame._from_data(data, index)

