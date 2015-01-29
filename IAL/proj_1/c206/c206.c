	
/* c206.c **********************************************************}
{* T�ma: Dvousm�rn� v�zan� line�rn� seznam
**
**                   N�vrh a referen�n� implementace: Bohuslav K�ena, ��jen 2001
**                            P�epracovan� do jazyka C: Martin Tu�ek, ��jen 2004
**                                             �pravy: Bohuslav K�ena, ��jen 2013
**
** Implementujte abstraktn� datov� typ dvousm�rn� v�zan� line�rn� seznam.
** U�ite�n�m obsahem prvku seznamu je hodnota typu int.
** Seznam bude jako datov� abstrakce reprezentov�n prom�nnou
** typu tDLList (DL znamen� Double-Linked a slou�� pro odli�en�
** jmen konstant, typ� a funkc� od jmen u jednosm�rn� v�zan�ho line�rn�ho
** seznamu). Definici konstant a typ� naleznete v hlavi�kov�m souboru c206.h.
**
** Va��m �kolem je implementovat n�sleduj�c� operace, kter� spolu
** s v��e uvedenou datovou ��st� abstrakce tvo�� abstraktn� datov� typ
** obousm�rn� v�zan� line�rn� seznam:
**
**      DLInitList ...... inicializace seznamu p�ed prvn�m pou�it�m,
**      DLDisposeList ... zru�en� v�ech prvk� seznamu,
**      DLInsertFirst ... vlo�en� prvku na za��tek seznamu,
**      DLInsertLast .... vlo�en� prvku na konec seznamu, 
**      DLFirst ......... nastaven� aktivity na prvn� prvek,
**      DLLast .......... nastaven� aktivity na posledn� prvek, 
**      DLCopyFirst ..... vrac� hodnotu prvn�ho prvku,
**      DLCopyLast ...... vrac� hodnotu posledn�ho prvku, 
**      DLDeleteFirst ... zru�� prvn� prvek seznamu,
**      DLDeleteLast .... zru�� posledn� prvek seznamu, 
**      DLPostDelete .... ru�� prvek za aktivn�m prvkem,
**      DLPreDelete ..... ru�� prvek p�ed aktivn�m prvkem, 
**      DLPostInsert .... vlo�� nov� prvek za aktivn� prvek seznamu,
**      DLPreInsert ..... vlo�� nov� prvek p�ed aktivn� prvek seznamu,
**      DLCopy .......... vrac� hodnotu aktivn�ho prvku,
**      DLActualize ..... p�ep�e obsah aktivn�ho prvku novou hodnotou,
**      DLSucc .......... posune aktivitu na dal�� prvek seznamu,
**      DLPred .......... posune aktivitu na p�edchoz� prvek seznamu, 
**      DLActive ........ zji��uje aktivitu seznamu.
**
** P�i implementaci jednotliv�ch funkc� nevolejte ��dnou z funkc�
** implementovan�ch v r�mci tohoto p��kladu, nen�-li u funkce
** explicitn� uvedeno n�co jin�ho.
**
** Nemus�te o�et�ovat situaci, kdy m�sto leg�ln�ho ukazatele na seznam 
** p�ed� n�kdo jako parametr hodnotu NULL.
**
** Svou implementaci vhodn� komentujte!
**
** Terminologick� pozn�mka: Jazyk C nepou��v� pojem procedura.
** Proto zde pou��v�me pojem funkce i pro operace, kter� by byly
** v algoritmick�m jazyce Pascalovsk�ho typu implemenov�ny jako
** procedury (v jazyce C procedur�m odpov�daj� funkce vracej�c� typ void).
**/

#include "c206.h"

int solved;
int errflg;

void DLError() {
/*
** Vytiskne upozorn�n� na to, �e do�lo k chyb�.
** Tato funkce bude vol�na z n�kter�ch d�le implementovan�ch operac�.
**/	
    printf ("*ERROR* This program has performed an illegal operation.\n");
    errflg = TRUE;             /* glob�ln� prom�nn� -- p��znak o�et�en� chyby */
    return;
}

void DLInitList (tDLList *L)	{
/*
** Provede inicializaci seznamu L p�ed jeho prvn�m pou�it�m (tzn. ��dn�
** z n�sleduj�c�ch funkc� nebude vol�na nad neinicializovan�m seznamem).
** Tato inicializace se nikdy nebude prov�d�t nad ji� inicializovan�m
** seznamem, a proto tuto mo�nost neo�et�ujte. V�dy p�edpokl�dejte,
** �e neinicializovan� prom�nn� maj� nedefinovanou hodnotu.
**/
    /* Inicializace seznamu - v�echny ukazatele nastaveny na NULL */
    L->Act = NULL;
    L->First = NULL;
    L->Last = NULL;
}

void DLDisposeList (tDLList *L)	{
/*
** Zru�� v�echny prvky seznamu L a uvede seznam do stavu, v jak�m
** se nach�zel po inicializaci. Ru�en� prvky seznamu budou korektn�
** uvoln�ny vol�n�m operace free. 
**/
    tDLElemPtr tmp;
    while (L->First != NULL) {
        /* Ulo�en� ukazatele na prvek, kter� m� b�t smaz�n */
        tmp = L->First;
        /* P�esun k dal��mu prvku */
        L->First = L->First->rptr;
        /* Uvoln�n� star�ho prvku */
        free(tmp);
    }
    /* Nastaven� v�ech ukazatel� seznamu na NULL (jako p�i inicializaci) */
    L->Act = NULL;
    L->First = NULL;
    L->Last = NULL;
}

void DLInsertFirst (tDLList *L, int val)	{
/*
** Vlo�� nov� prvek na za��tek seznamu L.
** V p��pad�, �e nen� dostatek pam�ti pro nov� prvek p�i operaci malloc,
** vol� funkci DLError().
**/
    tDLElemPtr tmp;
	if ((tmp = malloc(sizeof(struct tDLElem))) == NULL) {
        /* Chyba p�i alokaci pam�ti */
        DLError();
    } else {
        /* Vlo�en� dat do nov�ho prvku */
        tmp->data = val;
        /* Jeliko� je prvn�, jeho lev� ukazatel je NULL */
        tmp->lptr = NULL;
        /* a prav� ukazuje na aktu�ln� First prvek */
        tmp->rptr = L->First;
        
        if (L->First != NULL) {
            /* 
             * Seznam nen� prazdn� - aktu�ln� First prvek bude m�t v lev�m ukazateli 
             * odkaz na nov� vkl�dan� prvek
             */
            L->First->lptr = tmp;
        } else {
            /* Seznam je pr�zdn� - Last bude odkazovat na nov� vkl�dan� prvek */
            L->Last = tmp;
        }
        /* Nov� vytvo�en� prvek se �ad� na 1. m�sto v seznamu */
        L->First = tmp;
    }
}

void DLInsertLast(tDLList *L, int val)	{
/*
** Vlo�� nov� prvek na konec seznamu L (symetrick� operace k DLInsertFirst).
** V p��pad�, �e nen� dostatek pam�ti pro nov� prvek p�i operaci malloc,
** vol� funkci DLError().
**/ 	
	tDLElemPtr tmp;
    if ((tmp = malloc(sizeof(struct tDLElem))) == NULL) {
        DLError();
    } else {
        /* Vlo�en� dat do nov�ho prvku */
        tmp->data = val;
        /* Jeliko� je posledn�, jeho prav� ukazatel je NULL */
        tmp->rptr = NULL;
        /* a lev� ukazuje na aktu�ln� Last prvek */
        tmp->lptr = L->Last;
        
        if (L->Last != NULL) {
            /*
             * Seznam nen� pr�zdn� - aktu�ln� Last prvek bude m�t v prav�m ukazateli
             * odkaz na nov� vkl�dan� prvek
             */
            L->Last->rptr = tmp;
        } else {
            /* Seznam je pr�zdn� - First bude odkazovat na nov� vkl�dan� prvek */
            L->First = tmp;
        }
        /* Nov� vytvo�en� prvek se �ad� na 1. m�sto v seznamu */
        L->Last = tmp;
    }
}

void DLFirst (tDLList *L)	{
/*
** Nastav� aktivitu na prvn� prvek seznamu L.
** Funkci implementujte jako jedin� p��kaz (nepo��t�me-li return),
** ani� byste testovali, zda je seznam L pr�zdn�.
**/
    /* Nastaven� aktivity na prvn� prvek */
	L->Act = L->First;
}

void DLLast (tDLList *L)	{
/*
** Nastav� aktivitu na posledn� prvek seznamu L.
** Funkci implementujte jako jedin� p��kaz (nepo��t�me-li return),
** ani� byste testovali, zda je seznam L pr�zdn�.
**/
    /* Nastaven� aktivity na posledn� prvek */
	L->Act = L->Last;
}

void DLCopyFirst (tDLList *L, int *val)	{
/*
** Prost�ednictv�m parametru val vr�t� hodnotu prvn�ho prvku seznamu L.
** Pokud je seznam L pr�zdn�, vol� funkci DLError().
**/
    if (L->First == NULL) {
        /* Pr�zdn� seznam */
        DLError();
    } else {
        /* Na�ten� hodnoty ze seznamu do prom�nn� */
        *val = L->First->data;
    }
}

void DLCopyLast (tDLList *L, int *val)	{
/*
** Prost�ednictv�m parametru val vr�t� hodnotu posledn�ho prvku seznamu L.
** Pokud je seznam L pr�zdn�, vol� funkci DLError().
**/
	if (L->Last == NULL) {
        /* Pr�zdn� seznam */
        DLError();
    } else {
        /* Na�ten� hodnoty ze seznamu do prom�nn� */
        *val = L->Last->data;
    }
}

void DLDeleteFirst (tDLList *L)	{
/*
** Zru�� prvn� prvek seznamu L. Pokud byl prvn� prvek aktivn�, aktivita 
** se ztr�c�. Pokud byl seznam L pr�zdn�, nic se ned�je.
**/
    /* Kontrola pr�zdn�ho seznamu */
	if (L->First != NULL) {
        if (L->Act == L->First) {
            /* Ztr�ta aktivity, pokud je aktivn� prvek prvn�m prvkem */
            L->Act = NULL;
        }
        tDLElemPtr tmp;
        /* Ulo�en� ukazatele na star� prvek */
        tmp = L->First;
        /* P�esun ukazatele First na n�sleduj�c� prvek */
        L->First = L->First->rptr;
        if (L->First == NULL) {
            /* Pokud je seznam pr�zdn�, je t�eba znullovat i ukazatel na Last */
            L->Last = NULL;
        } else {
            /* Pokud pr�zdn� nen�, mus�me znullovat lev� ukazatel nov�ho First prvku */
            L->First->lptr = NULL;
        }
        /* Uvoln�n� star�ho prvku */
        free(tmp);
    }
}	

void DLDeleteLast (tDLList *L)	{
/*
** Zru�� posledn� prvek seznamu L. Pokud byl posledn� prvek aktivn�,
** aktivita seznamu se ztr�c�. Pokud byl seznam L pr�zdn�, nic se ned�je.
**/ 
    /* Kontrola pr�zdn�ho seznamu */
	if (L->Last != NULL) {
        if (L->Act == L->Last) {
            /* Ztr�ta aktivity, pokud je aktivn� prvek posledn�m prvkem */
            L->Act = NULL;
        }
        tDLElemPtr tmp;
        /* Ulo�en� ukazatele na star� prvek */
        tmp = L->Last;
        /* P�esun ukazatele Last na p�edchoz� prvek */
        L->Last = L->Last->lptr;
        if (L->Last == NULL) {
            /* Pokud je seznam pr�zdn�, je t�eba znullovat i ukazatel na First */
            L->First = NULL;
        } else {
            /* Pokud pr�zdn� nen�, mus�me znullovat prav� ukazatel nov�ho Last prvku */
            L->Last->rptr = NULL;
        }
        /* Uvoln�n� star�ho prvku */
        free(tmp);
    }
}

void DLPostDelete (tDLList *L)	{
/*
** Zru�� prvek seznamu L za aktivn�m prvkem.
** Pokud je seznam L neaktivn� nebo pokud je aktivn� prvek
** posledn�m prvkem seznamu, nic se ned�je.
**/
    /* Kontrola pr�zdnosti seznamu a jestli nen� aktivn� prvek posledn�m */
	if ((L->Act != NULL) && (L->Act != L->Last)) {
        tDLElemPtr tmp;
        /* Ulo�en� ukazatele na star� prvek */
        tmp = L->Act->rptr;
        if (tmp != NULL) {
            /* Nastaven� nov�ho ukazatele aktivn�ho prvku */
            L->Act->rptr = tmp->rptr;
            if (tmp == L->Last) {
                /* Pokud je star� prvek posledn�m, je t�eba zm�nit Last ukazatel na Act */
                L->Last = L->Act;
            } else {
                /* Pokud nen�, je t�eba zm�nit lev� ukazatel jeho n�sledn�ka na Act */
                tmp->rptr->lptr = L->Act;
            }
            /* Uvoln�n� star�ho prvku */
            free(tmp);
        }
    }
}

void DLPreDelete (tDLList *L)	{
/*
** Zru�� prvek p�ed aktivn�m prvkem seznamu L .
** Pokud je seznam L neaktivn� nebo pokud je aktivn� prvek
** prvn�m prvkem seznamu, nic se ned�je.
**/
    /* Kontrola pr�zdnosti seznamu a jestli nen� aktivn� prvek prvn�m */
	if ((L->Act != NULL) && (L->Act != L->First)) {
        tDLElemPtr tmp;
        /* Ulo�en� ukazatele na star� prvek */
        tmp = L->Act->lptr;
        if (tmp != NULL) {
            /* Nastaven� nov�ho ukazatele aktivn�ho prvku */
            L->Act->lptr = tmp->lptr;
            if (tmp == L->First) {
                /* Pokud je star� prvek prvn�m, je t�eba zm�nit First ukazatel na Act */
                L->First = L->Act;
            } else {
                /* Pokud nen�, je t�eba zm�nit prav� ukazatel jeho p�edch�dce na Act */
                tmp->lptr->rptr = L->Act;
            }
            /* Uvoln�n� star�ho prvku */
            free(tmp);
        }
    }
}

void DLPostInsert (tDLList *L, int val) {
/*
** Vlo�� prvek za aktivn� prvek seznamu L.
** Pokud nebyl seznam L aktivn�, nic se ned�je.
** V p��pad�, �e nen� dostatek pam�ti pro nov� prvek p�i operaci malloc,
** vol� funkci DLError().
**/
    /* Kontrola aktivity seznamu */
	if (L->Act != NULL) {
        tDLElemPtr tmp;
        if ((tmp = malloc(sizeof(struct tDLElem))) == NULL) {
            /* Chyba p�i alokaci pam�ti */
            DLError();
        } else {
            /* Ulo�en� hodnoty do nov�ho prvku */
            tmp->data = val;
            /* Nastaven� adekv�tn�ch ukazatel� nov�ho prvku */
            tmp->rptr = L->Act->rptr;
            tmp->lptr = L->Act;
            
            /* Nastaven� prav�ho ukazatele aktivn�ho prvku na nov� prvek */
            L->Act->rptr = tmp;
            if (L->Act == L->Last) {
                /* 
                 * Pokud je aktivn� prvek posledn�m, je t�eba zm�nit Last
                 * ukazatel na nov� prvek (jeliko� ten bude nyn� posledn�m)
                 */
                L->Last = tmp;
            } else {
                /* 
                 * Pokud nen� aktivn� prvek posledn�m, je t�eba zm�nit ukazatel 
                 * n�sledn�ka nov�ho prvku na tento nov� prvek
                 */
                tmp->rptr->lptr = tmp;
            }
        }
    }
}

void DLPreInsert (tDLList *L, int val)		{
/*
** Vlo�� prvek p�ed aktivn� prvek seznamu L.
** Pokud nebyl seznam L aktivn�, nic se ned�je.
** V p��pad�, �e nen� dostatek pam�ti pro nov� prvek p�i operaci malloc,
** vol� funkci DLError().
**/
    /* Kontrola aktivity seznamu */
	if (L->Act != NULL) {
        tDLElemPtr tmp;
        if ((tmp = malloc(sizeof(struct tDLElem))) == NULL) {
            /* Chyba p�i alokaci pam�ti */
            DLError();
        } else {
            /* Ulo�en� hodnoty do nov�ho prvku */
            tmp->data = val;
            /* Nastaven� adekv�tn�ch ukazatel� nov�ho prvku */
            tmp->lptr = L->Act->lptr;
            tmp->rptr = L->Act;
            
            /* Nastaven� lev�ho ukazatele aktivn�ho prvku na nov� prvek */
            L->Act->lptr = tmp;
            if (L->Act == L->First) {
                /* 
                 * Pokud je aktivn� prvek prvn�m, je t�eba zm�nit First
                 * ukazatel na nov� prvek (jeliko� ten bude nyn� prvn�m)
                 */
                L->First = tmp;
            } else {
                /* 
                 * Pokud nen� aktivn� prvek prvn�m, je t�eba zm�nit ukazatel 
                 * p�edch�dce nov�ho prvku na tento nov� prvek
                 */
                tmp->lptr->rptr = tmp;
            }
        }
    }
}

void DLCopy (tDLList *L, int *val)	{
/*
** Prost�ednictv�m parametru val vr�t� hodnotu aktivn�ho prvku seznamu L.
** Pokud seznam L nen� aktivn�, vol� funkci DLError ().
**/
    /* Kontrola aktivity seznamu */
	if (L->Act == NULL) {
        DLError();
    } else {
        /* Ulo�en� hodnoty aktivn�ho prvku do prom�nn� val */
        *val = L->Act->data;
    }
}

void DLActualize (tDLList *L, int val) {
/*
** P�ep�e obsah aktivn�ho prvku seznamu L.
** Pokud seznam L nen� aktivn�, ned�l� nic.
**/
    /* Kontrola aktivity seznamu */
	if (L->Act != NULL) {
        /* Ulo�en� hodnoty prom�nn� val do aktu�ln�ho prvku seznamu */
        L->Act->data = val;
    }
}

void DLSucc (tDLList *L)	{
/*
** Posune aktivitu na n�sleduj�c� prvek seznamu L.
** Nen�-li seznam aktivn�, ned�l� nic.
** V�imn�te si, �e p�i aktivit� na posledn�m prvku se seznam stane neaktivn�m.
**/
    /* Kontrola aktivity seznamu */
	if (L->Act != NULL) {
        if (L->Act == L->Last) {
            /* Pokud je aktivn� prvek posledn�m, aktivita se ztr�c� */
            L->Act = NULL;
        } else {
            /* Aktivita se p�esune na n�sledn�ka aktivn�ho prvku */
            L->Act = L->Act->rptr;
        }
    }
}


void DLPred (tDLList *L)	{
/*
** Posune aktivitu na p�edchoz� prvek seznamu L.
** Nen�-li seznam aktivn�, ned�l� nic.
** V�imn�te si, �e p�i aktivit� na prvn�m prvku se seznam stane neaktivn�m.
**/
    /* Kontrola aktivity seznamu */
	if (L->Act != NULL) {
        if (L->Act == L->First) {
            /* Pokud je aktivn� prvek prvn�m, aktivita se ztr�c� */
            L->Act = NULL;
        } else {
            /* Aktivita se p�esune na p�edch�dce aktivn�ho prvku */
            L->Act = L->Act->lptr;
        }
    }
}

int DLActive (tDLList *L) {		
/*
** Je-li seznam aktivn�, vrac� true. V opa�n�m p��pad� vrac� false.
** Funkci implementujte jako jedin� p��kaz.
**/
    /* Pokud Act == NULL, seznam aktivn� nen� */
    return (L->Act != NULL) ? TRUE : FALSE;
}

/* Konec c206.c*/
