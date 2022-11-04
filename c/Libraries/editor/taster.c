/* Headere til funksjoner som ikke er definert i editor.h */
void  ed_bs(void);
void  ed_ctrlend(void);
void  ed_ctrlhome(void);
void  ed_ctrlJ(void);
void  ed_ctrlN(void);
void  ed_ctrlpgdn(void);
void  ed_ctrlpgup(void);
void  ed_ctrlY(void);
int   ed_del(void);
void  ed_end(void);
void  ed_home(void);
void  ed_ins(void);
void  ed_ordhoyre(void);
void  ed_ordvenstre(void);
void  ed_pgdn(void);
void  ed_pgup(void);
int   ed_pilhoyre(void);
int   ed_pilned(void);
int   ed_pilopp(void);
int   ed_pilvenstre(void);
void  ed_return(void);
void  ed_tab(void);
int   ed_vanligtegn(int c);


int ed_pilvenstre(void)
{
    if (ed_kolonne > 0) {
        if (ed_kolonne == ed_relx)
            ed_scrollhoyre();
        else {
            gotoxy(wherex() - 1, wherey());
            --ed_kolonne;
        }
        ed_viskolonnenr();
        return(0);
    } else
        return(1);
}

int ed_pilhoyre(void)
{
    if (ed_kolonne < makskolonner - 1) {
        if (ed_kolonne - ed_relx >= ed_vinvidde - 2)
            ed_scrollvenstre();
        else {
            gotoxy(wherex() + 1, wherey());
            ++ed_kolonne;
        }
        ed_viskolonnenr();
        return(0);
    } else
        return(1);
}

int ed_pilopp(void)
{
    if (ed_linjenr > 0) {
        ed_trim(ed_linjenr);
        if (ed_linjenr == ed_rely)
            ed_scrollned();
        else {
            gotoxy(wherex(), wherey() - 1);
            --ed_linjenr;
        }
        ed_vislinjenr();
        return(0);
    } else
        return(1);
}

int ed_pilned(void)
{
    if (ed_linjenr < ed_antlin - 1) {
        ed_trim(ed_linjenr);
        if (ed_linjenr - ed_rely >= ed_vinhoyde - 1)
            ed_scrollopp();
        else {
            gotoxy(wherex(), wherey() + 1);
            ++ed_linjenr;
        }
        ed_vislinjenr();
        return(0);
    } else
        return(1);
}

void ed_home(void)
{
    ed_kolonne = 0;
    gotoxy(1, wherey());
    if (ed_relx > 0) {
        ed_relx = 0;
        ed_vistekst();
    }
    ed_viskolonnenr();
}

void ed_end(void)
{
    ed_trim(ed_linjenr);
    ed_kolonne = strlen(ed_ln[ed_linjenr]);
    if (ed_kolonne >= makskolonner)
        ed_kolonne = makskolonner - 1;
    if (ed_kolonne < ed_relx) {
        ed_relx = ed_kolonne;
        ed_vistekst();
    } else if (ed_kolonne > ed_relx + ed_vinvidde - 2) {
        ed_relx = ed_kolonne - ed_vinvidde + 2;
        if (ed_relx < 0)
            ed_relx = 0;
        ed_vistekst();
    }
    gotoxy(ed_kolonne - ed_relx + 1, wherey());
    ed_viskolonnenr();
}

void ed_ins(void)
{
    ed_insstatus = !ed_insstatus;
    ed_visinsstatus();
}

void ed_pgdn(void)
{
    int q;

    q = ed_rely;
    ed_rely += ed_vinhoyde - 1;
    while (ed_rely >= ed_antlin)
        --ed_rely;
    ed_linjenr += ed_vinhoyde - 1;
    while (ed_linjenr >= ed_antlin)
        --ed_linjenr;
    if (q != ed_rely)
        ed_vistekst();
    ed_vislinjenr();
    gotoxy(wherex(), 1 + ed_linjenr - ed_rely);
}

void ed_pgup(void)
{
    int q;

    q = ed_rely;
    ed_rely -= ed_vinhoyde - 1;
    while (ed_rely < 0)
        ++ed_rely;
    ed_linjenr -= ed_vinhoyde - 1;
    while (ed_linjenr < 0)
        ++ed_linjenr;
    if (q != ed_rely)
        ed_vistekst();
    ed_vislinjenr();
    gotoxy(wherex(), 1 + ed_linjenr - ed_rely);
}

void ed_ctrlhome(void)
{
    ed_linjenr = ed_rely;
    gotoxy(wherex(), 1);
    ed_vislinjenr();
}

void ed_ctrlend(void)
{
    ed_linjenr = ed_rely + ed_vinhoyde - 1;
    if (ed_linjenr >= ed_antlin)
        ed_linjenr = ed_antlin - 1;
    gotoxy(wherex(), 1 + ed_linjenr - ed_rely);
    ed_vislinjenr();
}

void ed_ctrlpgup(void)
{
    int q, l;

    q = ed_rely;
    l = ed_relx;
    ed_rely = ed_relx = ed_linjenr = ed_kolonne = 0;
    if (q != ed_rely || l != ed_relx)
        ed_vistekst();
    ed_viskolonnenr();
    ed_vislinjenr();
    gotoxy(1, 1);
}

void ed_ctrlpgdn(void)
{
    int q, l;

    q = ed_rely;
    l = ed_relx;
    ed_relx = ed_kolonne = 0;
    ed_linjenr = ed_antlin - 1;
    ed_rely = ed_linjenr - ed_vinhoyde + 1;
    if (ed_rely < q)
        ed_rely = q;
    if (ed_rely < 0)
        ed_rely = 0;
    if (q != ed_rely || l != ed_relx)
        ed_vistekst();
    ed_viskolonnenr();
    ed_vislinjenr();
    gotoxy(1, 1 + ed_linjenr - ed_rely);
}



int ed_del(void)
{
    int q, l;

    if (ed_kolonne < (l = strlen(ed_ln[ed_linjenr]))) {
        for (q = ed_kolonne; q < l; q++)
            ed_ln[ed_linjenr][q] = ed_ln[ed_linjenr][q + 1];
        ed_vislinje(ed_linjenr);
        return(0);
    } else if (ed_linjenr < ed_antlin - 1) {
        strncat(ed_ln[ed_linjenr], ed_ln[ed_linjenr + 1], makskolonner - l);
        ed_vislinje(ed_linjenr);
        if (l + strlen(ed_ln[ed_linjenr + 1]) == strlen(ed_ln[ed_linjenr])) {
            ed_slettlinje(ed_linjenr + 1);
            if (ed_linjenr - ed_rely < ed_vinhoyde - 1) {
                cursoff();
                gotoxy((q = wherex()), wherey() + 1);
                ed_nydelline();
                gotoxy(q, wherey() - 1);
                curson();
            }
        } else {
            strcpy(ed_ln[ed_linjenr + 1], ed_ln[ed_linjenr + 1] + strlen(ed_ln[ed_linjenr]) - l);
            if (ed_linjenr - ed_rely < ed_vinhoyde - 1) {
                cursoff();
                gotoxy((q = wherex()), wherey() + 1);
                ed_vislinje(ed_linjenr + 1);
                gotoxy(q, wherey() - 1);
                curson();
            }
        }
        return(0);
    } else
        return(1);
}

void ed_bs(void)
{
    ed_trim(ed_linjenr);
    if (strlen(ed_ln[ed_linjenr]) < ed_kolonne) {
        ed_pilvenstre();
        return;
    }
    if (ed_pilvenstre()) {
        if (ed_pilopp())
            return;
        ed_end();
    }
    ed_del();
}

void ed_return(void)
{
    if (ed_insstatus)
        ed_ctrlN();
    ed_home();
    ed_pilned();
    if (ed_indent && ed_linjenr > 0 && !strlen(ed_ln[ed_linjenr]) && strlen(ed_ln[ed_linjenr - 1]) > 0)
        while (ed_ln[ed_linjenr - 1][ed_kolonne] == ' ')
            ed_pilhoyre();
}

void ed_ctrlN(void)
{
    if (ed_settinnlinje(ed_linjenr) == 0) {
        ed_vislinje(ed_linjenr);
        if (wherey() < ed_vinhoyde) {
            gotoxy(wherex(), wherey() + 1);
            ed_nyinsline();
            ed_vislinje(ed_linjenr + 1);
            gotoxy(wherex(), wherey() - 1);
        }
    }
}

void ed_ctrlJ(void)
{
    ed_indent = !ed_indent;
    ed_visindent();
}

void ed_ctrlY(void)
{
    int q;

    if (ed_linjenr == ed_antlin - 1) {
        ed_ln[ed_linjenr][0] = '\0';
        ed_vislinje(ed_linjenr);
    } else {
        ed_kolonne = 0;
        gotoxy(1, wherey());
        if (ed_relx > 0) {
            ed_relx = 0;
            ed_vistekst();
        }
        ed_viskolonnenr();
        q = wherey();
        ed_slettlinje(ed_linjenr);
        ed_nydelline();
        gotoxy(1, ed_vinhoyde);
        ed_vislinje(ed_rely + ed_vinhoyde - 1);
        ed_vislinjenr();
        gotoxy(1, q);
    }
}

void ed_tab(void)
{
    if (!ed_insstatus)
        while (!ed_pilhoyre() && ed_kolonne % 8 != 0)
            ;
    else
        while (!ed_tolktegn(' ') && ed_kolonne < makskolonner - 1 && ed_kolonne % 8 != 0)
            ;
}

int ed_vanligtegn(int c)
{
    int l, q;
    int ret = 0;

    if (ed_kolonne < makskolonner) {
        l = strlen(ed_ln[ed_linjenr]);
        if (ed_insstatus) {
            for (q = l; q > ed_kolonne; q--)
                ed_ln[ed_linjenr][q] = ed_ln[ed_linjenr][q - 1];
            if (l < makskolonner)
                ++l;
            ed_ln[ed_linjenr][l] = '\0';
        } else
            if (ed_ln[ed_linjenr][ed_kolonne] == '\0')
                ed_ln[ed_linjenr][ed_kolonne + 1] = '\0';
        ed_ln[ed_linjenr][ed_kolonne] = c;
        ed_vislinje(ed_linjenr);
        if (ed_kolonne - ed_relx >= ed_vinvidde - 2)
            ed_scrollvenstre();
        else {
            gotoxy(wherex() + 1, wherey());
            ++ed_kolonne;
        }
        ed_viskolonnenr();
    } else
        ret = 1;
    return(ret);
}

void ed_ordvenstre(void)
{
    if (ed_kolonne == 0) {
        if (ed_pilopp())
            return;
        ed_end();
    } else
        while (ed_kolonne > 0 && !ed_ordtegn(ed_ln[ed_linjenr][ed_kolonne - 1]) && !ed_pilvenstre())
            ;
    while (ed_kolonne > 0 && ed_ordtegn(ed_ln[ed_linjenr][ed_kolonne - 1]) && !ed_pilvenstre())
        ;
}

void ed_ordhoyre(void)
{
    int l;

    ed_trim(ed_linjenr);
    if (ed_kolonne >= (l = strlen(ed_ln[ed_linjenr])) || ed_kolonne == makskolonner - 1) {
        if (ed_pilned())
            return;
        ed_home();
        l = strlen(ed_ln[ed_linjenr]);
    } else
        while (ed_kolonne < l && ed_ordtegn(ed_ln[ed_linjenr][ed_kolonne]) && !ed_pilhoyre())
            ;
    while (ed_kolonne < l && !ed_ordtegn(ed_ln[ed_linjenr][ed_kolonne]) && !ed_pilhoyre())
        ;
}
