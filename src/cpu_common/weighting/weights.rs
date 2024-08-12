// Copyright 2023 shadow3aaa@gitbub.com
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

use std::collections::HashMap;

use crate::cpu_common::cpu_info::Info;

#[derive(Debug)]
pub struct Weights {
    pub map: HashMap<Vec<i32>, f64>,
}

impl Weights {
    pub fn new(policys: &Vec<Info>) -> Self {
        let map = policys
            .iter()
            .map(|policy| (policy.cpus.clone(), 0.0))
            .collect();
        Self { map }
    }

    pub fn weight(&self, cpus: &Vec<i32>) -> f64 {
        (self.map.get(cpus).unwrap() + 1.0).min(1.8)
    }
}
