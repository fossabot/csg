#! /bin/bash
#
# Copyright 2009 The VOTCA Development Team (http://www.votca.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if [ "$1" = "--help" ]; then
cat <<EOF
${0##*/}, version %version%
This script implemtents the function initialize for the PMF calculator

Usage: ${0##*/}

EOF
  exit 0
fi

last_dir=$(get_last_step_dir)
pullgroup0=$(csg_get_interaction_property .pmf.pullgroup0)
pullgroup1=$(csg_get_interaction_property .pmf.pullgroup1)
kBT=$(csg_get_property cg.inverse.kBT)

forcefile="forces_${pullgroup0}_${pullgroup1}.all.d"
potfile="pmf_${pullgroup0}_${pullgroup1}.all.d"
forcefile2="forces_${pullgroup0}_${pullgroup1}.pg.d"
potfile2="pmf_${pullgroup0}_${pullgroup1}.pg.d"

echo "#dist <force> error flag" > ${forcefile}
sims="$(find ${last_dir} -type d -name "sim_???*" | sort)"
for sim in ${sims}; do
  echo "Doing ${sim}"
  dist="$(get_from_mdp pull_init1 ${sim}/grompp.mdp)"
  [ -f "${sim}/pullf.xvg" ] || die "Could not find file ${sim}/pullf.xvg"
  [ -f "${sim}/pullf2.xvg" ] || die "Could not find file ${sim}/pullf.xvg"
  force="$(${CSGSHARE}/scripts/inverse/avg_bl.awk -v col=2 ${sim}/pullf.xvg | awk '/^[^#]/{print $1,$2}')"
  force2="$(${CSGSHARE}/scripts/inverse/avg_bl.awk -v col=2 ${sim}/pullf2.xvg | awk '/^[^#]/{print $1,$2}')"
  echo "dist: $dist force: $force"
  echo "$dist $force i" >>  ${forcefile}
  echo "dist: $dist force: $force2"
  echo "$dist $force2 i" >>  ${forcefile2}
done

# Copy grompp from last sim to current dir
cp ${sim}/grompp.mdp .

echo "Calculating pmf"
# Integrate to get pot
do_external table integrate --with-errors --with-S --kbT $kBT ${forcefile} ${potfile}
do_external table integrate --with-errors --with-S --kbT $kBT ${forcefile2} ${potfile2}