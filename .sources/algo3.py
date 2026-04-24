import os
import re
import threading
import time
from pathlib import Path
from clsLetter import clLetter
from clsLetters import clLetters


class cl_algo3(threading.Thread):
    # region sub classes
    class cl_dico(list):
        def __init__(self):
            for i in range(0, 26):
                dic = {}
                self.append(dic)
                for n in range(0, 27):
                    lst = []
                    l = chr(65 + n)
                    dic[l] = lst

        def fn_load_ana(self, fileName: str, myChaine: str):
            file = str(Path(__file__).parent / "dicos") + "/" + fileName + ".dic"
            with open(file, "r") as f:
                row = f.readline()
                while row:
                    myMot = row.replace('\n', '')
                    if cl_algo3.fn_isanag(self, myMot=myMot, myChaine=myChaine, lgd=len(myMot)):
                        self.fn_addWord(myMot)
                    row = f.readline()

        def fn_get_dic(self, index) -> dict:
            return self[index]

        def fn_addWord(self, w: str):
            dic: {} = self[len(w)]
            # lst: [] = dic[w[0]]
            # lst.append(w)
            for n in range(0, len(w)):
                if not w[0:n] in dic.keys(): dic[w[0:n]] = []
                lst2: [] = dic[w[0:n]]
                lst2.append(w)

            # lst3: [] = dic[w[0 - 2]]
            # lst3.append(w)

        # renvoie liste des mots de la longueur index et commençant par chaine alpha
        def fn_get_lst(self, index: int, alpha: str, l):
            dic = self[index]
            if not alpha[0:l] in dic.keys(): return []
            lst: [] = dic[alpha[0:l]]
            return lst

        def fn_removeWord(self, w: str):
            dic: {} = self[len(w)]
            lst: [] = dic[w[0]]
            lst.remove(w)

        def fn_get_fullLst(self) -> list:
            rslt = []
            lst = []
            for n in range(0, len(self)):
                for lst in self[n]:
                    rslt.extend(lst)

            return rslt

    class cl_combis():
        def __init__(self):
            self._lstObj: [] = []
            for i in range(0, 26):
                lst = []
                self._lstObj.append(lst)

            self._lstStr: [] = []
            for i in range(0, 26):
                lst = []
                self._lstStr.append(lst)

            self.__coLetters = clLetters()

        # carré de lettres de référence pour la détection
        @property
        def pp_square(self) -> clLetters:
            return self.__coLetters

        @pp_square.setter
        def pp_square(self, value: clLetters):
            self.__coLetters = value

        # liste de liste des objets lettres regroupés par longueur
        @property
        def pp_lst_obj(self):
            return self._lstObj

        # liste de liste des chaines regroupées par longueur
        @property
        def pp_lst_str(self):
            return self._lstStr

        # ajout de combinaison à la liste des obj trouvés et chaine à liste des chaines correspondante
        def fn_add_combi(self, combi: clLetters):
            lst0: [] = self._lstObj[len(combi.pp_text)]
            lst0.append(combi)

            lst1: [] = self._lstStr[len(combi.pp_text)]
            lst1.append(combi.pp_text)

        # ajout de combinaison sur la base des coordonnées dans le carré en référence
        def fn_add_combi_byCoords(self, lstCoords: []):
            newCombi = clLetters()
            ele: clLetter

            for strCoord in lstCoords:
                coords = re.findall('..', strCoord)
                for k in self.pp_square.keys():
                    cLtr: clLetter = self.pp_square[k]
                    if cLtr.pp_x == int(coords[0]) and cLtr.pp_y == int(coords[1]):
                        newCombi.fn_add_cletter(cLtr)

            self.fn_add_combi(newCombi)

        def fn_get_lst_str(self) -> []:
            lst = []
            for i in range(25, 1, -1):
                subLst: [] = self._lstStr[i]
                subLst.sort()
                if (len(subLst) > 0):
                    lst.extend(subLst)
            return lst

        def fn_get_lst_combis(self) -> []:
            lst = []
            for i in range(25, 1, -1):
                subLst: [] = self._lstObj[i]
                lst.extend(subLst)
            return lst

        def fn_get_lst_combiCoords(self) -> []:
            rslt = []
            cLtrs: clLetters
            for cLtrs in self.fn_get_lst_combis():
                rslt.append(''.join(cLtrs.fn_get_coords()))
            return rslt

        def fn_sort_combis(self):
            lst = []
            for i in range(len(self._lstStr) - 1, 1, -1):
                subLst: [] = self._lstStr[i]
                subLst.sort()
                oldLstCombis = self._lstObj[i]
                newLstCombis = []
                ltrs: clLetters

                for mot in subLst:
                    for ltrs in oldLstCombis:
                        if ltrs.pp_text == mot: newLstCombis.append(ltrs)
                self._lstObj[i] = newLstCombis

    # endregion

    # region constructor
    def __init__(self):
        threading.Thread.__init__(self)
        self._cCombis = self.cl_combis()  # resultat recherche liste de clLetters
        self.pp_square: clLetters = clLetters()
        self._mySize: int = 0
        self._nbSeek: int = 0
        self._nbRslt: int = 0
        self._totalSuites = []
        self._lstBadStart = {}
        self._cDico = self.cl_dico()
        self._isBusy = False

    @property
    def pp_square(self) -> clLetters:
        return self.__coLetters

    @pp_square.setter
    def pp_square(self, value: clLetters):
        self.__coLetters = value
        self._cCombis.pp_square = value

    @property
    def pp_is_busy(self) -> bool:
        return self._isBusy

    @pp_is_busy.setter
    def pp_is_busy(self,value:bool):
        self._isBusy=value

    # endregion

    # region search
    def fn_searchReset(self):
        self._lstBadStart.clear()
        self._cCombis = self.cl_combis()
        self.pp_square.fn_nearLettersDetectAll()
        self._cCombis.pp_square = self.pp_square
        self._totalSuites.clear()
        self._cDico = self.cl_dico()
        self._nbSeek = 0
        self._nbRslt = 0


    def run(self):
        self.fn_searchReset()
        if len(self.pp_square.pp_text) == 0: return
        self.fn_getscra(self.pp_square.pp_text)
        self.fn_detectCombi()
        self._cCombis.fn_sort_combis()


    def fn_isanag(self, myMot: str, myChaine: str, lgd: int):
        v: int = 0
        posCar: int = 0
        k: int = 0

        for k in range(0, lgd):
            posCar = myChaine.find(myMot[k])
            if posCar >= 0:
                v += 1
                if v >= lgd: break
                myChaine = myChaine.replace(myMot[k], '', 1)

        if v >= lgd:
            return True
        else:
            return False

    def fn_getscra(self, mychaine: str):
        t0 = time.perf_counter()
        # clear tbDico
        self._cDico = self.cl_dico()
        self._cDico.fn_load_ana("ods7", mychaine)
        print("recherche anagrammes effectuée en  : " + str(time.perf_counter() - t0))

    def fn_detectCombi(self):
        t0 = time.perf_counter()
        n: int
        t: float
        myCoSol: clLetters

        for k in self.pp_square.keys():
            ltr: clLetter = self.pp_square[k]
            ltr.isActif = True

            myCoSol = clLetters()
            myCoSol.fn_add_cletter(ltr)
            self.fn_seekSoluce(myCoSol)

        print("parcours des possibles effectué en  : " + str(time.perf_counter() - t0))

    def fn_seekSoluce(self, myCoSol: clLetters):
        nearLtr: clLetter
        newLtr: clLetter
        newCoLtr: clLetters
        myStr: str = ""
        lastLtr: clLetter
        bInSuites: bool
        bInCombi: bool
        intChkWrd: int = 0
        self._nbSeek += 1
        lastLtr = myCoSol.pp_lastLetter
        if len(lastLtr.pp_nearLetters) == 0: lastLtr.pp_nearLetters = self.pp_square.fn_nearLettersDetect(lastLtr)
        nearLetters: clLetters = lastLtr.pp_nearLetters
        for k in nearLetters.keys():
            nearLtr = nearLetters[k]
            if len(myCoSol) < 15 and not myCoSol.has_key(k):
                myStr = myCoSol.pp_text + nearLtr.pp_stLetter

                self._totalSuites.append(myStr)
                # # self._totalSuites.append(myStr+" "+".".join(myCoSol.keys()))
                # strSuite =''.join(sorted(myStr))
                # bInSuites =strSuite in self._totalSuites
                # if not bInSuites : self._totalSuites.append(strSuite)
                # myStr=myCoSol.pp_text + nearLtr.pp_stLetter

                lastChck = intChkWrd
                intChkWrd = 0
                if len(myStr) > 2:
                    if not myStr in self._lstBadStart.keys():
                        lstCombi: [] = self._cCombis.pp_lst_str[len(myStr)]
                        bInCombi = myStr in lstCombi
                        if bInCombi:
                            intChkWrd = 1
                        else:
                            intChkWrd = self.fn_checkWord(myStr)
                else:
                    intChkWrd = 1

                if intChkWrd > 0:
                    # newLtr = nearLtr.fn_clone()
                    newCoLtr = myCoSol.fn_cloneLetters()
                    newCoLtr.fn_add_cletter(nearLtr)

                if intChkWrd >= 2:
                    self._cCombis.fn_add_combi(newCoLtr)
                    self._nbRslt += 1
                    self._cDico.fn_removeWord(myStr)

                if intChkWrd == 2:
                    # self.fn_removeFromDico(myStr)
                    intChkWrd = 0

                if intChkWrd == 0:
                    self._lstBadStart[myStr] = myStr

                if intChkWrd > 0: self.fn_seekSoluce(newCoLtr)

    def fn_removeFromDico(self, myStr: str):
        strRacine = myStr[0:len(myStr)]
        tbRemove = []
        for i in range(len(myStr) + 1, 16):
            subTb = self._cDico.fn_get_lst(i, myStr)
            for m in subTb:
                if str(m).startswith(strRacine):
                    tbRemove.append(m)
        for m in tbRemove: self._cDico.fn_removeWord(m)

    def fn_checkWord(self, myStr: str) -> int:
        n: int = len(myStr)
        i: int
        j: int
        testStr: str
        rslt: int = 0
        tb: [] = self._cDico.fn_get_lst(len(myStr), myStr, len(myStr) - 1)

        # test si un des mots cible est identique à cette chaine
        if myStr in tb: rslt = 2

        # test si un des mots cibles commence par cette chaine
        bFind: bool = False
        for i in range(15, n, -1):
            tb: [] = self._cDico.fn_get_lst(i, myStr, len(myStr) - 1)
            for mot in tb:
                if mot.startswith(myStr):
                    bFind = True
                    break
            if bFind:
                rslt += 1
                break

        # self._dicStarts[myStr]=rslt
        return rslt

    # endregion

    # region files
    def fn_export_rslt(self, fileName: str):
        # enregistrement des combis
        fileCombi = fileName + "_resultats.txt"
        try:
            os.remove(str(fileCombi))
        except OSError as e:
            a = 1
        with open(str(fileCombi), "a") as f:
            f.writelines(self._cCombis.fn_get_lst_str())

        # enregistrement des suites
        fileSuite = fileName + "_suites.txt"
        try:
            os.remove(str(fileSuite))
        except OSError as e:
            a = 1
        with open(str(fileSuite), "a") as f:
            for suite in self._totalSuites:
                f.write("\n" + suite)

        # enregistrement des possibles
        fileAna = fileName + "_st_anagrammes.txt"
        try:
            os.remove(str(fileAna))
        except OSError as e:
            a = 1
        with open(str(fileAna), "a") as f:
            for myMot in self._cDico.fn_get_fullLst():
                f.write("\n" + myMot)

    # endregion
