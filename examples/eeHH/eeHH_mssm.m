(*
	eeHH_mssm.m
		generates the Fortran code for
		e^+ e^- -> H^+ H^- in the MSSM
		this file is part of FormCalc
		last modified 13 Feb 03 th

Reference: J. Guasch, W. Hollik, A. Kraft,
           Nucl. Phys. B596 (2001) 66 [hep-ph/9911452].

Note: the QED contributions are not taken into account. To plug
the QED part back in, comment out the parts in DiagramSelect that
eliminate a V[1].

*)


<< FeynArts`

<< FormCalc`


time1 = SessionTime[]

CKM = IndexDelta

Small[ME] = Small[ME2] = 0


process = {-F[2, {1}], F[2, {1}]} -> {-S[5], S[5]}

SetOptions[InsertFields,
  Model -> "MSSM", Restrictions -> NoLightFHCoupling]


SetOptions[Paint, PaintLevel -> {Classes}, ColumnsXRows -> {4, 5}]

(* take the comments out if you want the diagrams painted
DoPaint[diags_, file_] := (
  If[ FileType["diagrams"] =!= Directory,
    CreateDirectory["diagrams"] ];
  Paint[diags,
    DisplayFunction -> (Display["diagrams/" <> file <> ".ps", #]&)]
)
*)


Print["Counter terms"]

tops = CreateCTTopologies[1, 2 -> 2,
  ExcludeTopologies -> {TadpoleCTs, WFCorrectionCTs}];
	(* this is because there are no counter terms in MSSM.mod yet: *)
ins = InsertFields[tops, process /. S[5] -> S[3], Model -> "SMc"];
TheLabel[S[3]] = "H";
DoPaint[ins, "counter"];
counter = CreateFeynAmp[ins] /. SW -> -SW


Print["Born"]

tops = CreateTopologies[0, 2 -> 2];
ins = InsertFields[tops, process];
DoPaint[ins, "born"];
born = CalcFeynAmp[bornamp = CreateFeynAmp[ins]]

counter = Head[bornamp]@@ counter


Print["Self energies"]

tops = CreateTopologies[1, 2 -> 2, SelfEnergiesOnly];
ins = InsertFields[tops, process];
DoPaint[ins, "self"];
self = CalcFeynAmp[
  CreateFeynAmp[ins],
  Select[counter, DiagramType[#] == 2 &]]


Print["Vertices"]

tops = CreateTopologies[1, 2 -> 2, TrianglesOnly];
ins = InsertFields[tops, process];
ins = DiagramSelect[ins, FreeQ[#, Field[5] -> S]&];
DoPaint[ins, "vert"];
vert = CalcFeynAmp[
  CreateFeynAmp[ins],
  Select[counter, DiagramType[#] == 1 &]]


Print["Boxes"]

tops = CreateTopologies[1, 2 -> 2, BoxesOnly];
ins = InsertFields[tops, process];
DoPaint[ins, "box"];
box = CalcFeynAmp[
  CreateFeynAmp[ins],
  Select[counter, DiagramType[#] == 0 &]]


Hel[_] = 0;
hel = HelicityME[All, born]


WriteSquaredME[born, {self, vert, box}, hel, Abbr[], "fortran_mssm",
  Drivers -> "drivers_mssm"]


	(* dZGp1 should really be dZHp1, but is a temporary hack
	   until the "real" MSSM counterterms are implemented *)
RenConst[ dZGp1 ] := -ReTilde[DSelfEnergy[S[5] -> S[5], MHp]]

WriteRenConst[{self, vert, box}, "fortran_mssm"]


Print["time used: ", SessionTime[] - time1]

