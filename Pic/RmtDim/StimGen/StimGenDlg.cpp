// StimGenDlg.cpp : implementation file
//

#include "stdafx.h"
#include "StimGen.h"
#include "StimGenDlg.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CAboutDlg dialog used for App About

class CAboutDlg : public CDialog
{
public:
	CAboutDlg();

// Dialog Data
	//{{AFX_DATA(CAboutDlg)
	enum { IDD = IDD_ABOUTBOX };
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CAboutDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	//{{AFX_MSG(CAboutDlg)
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialog(CAboutDlg::IDD)
{
	//{{AFX_DATA_INIT(CAboutDlg)
	//}}AFX_DATA_INIT
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CAboutDlg)
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialog)
	//{{AFX_MSG_MAP(CAboutDlg)
		// No message handlers
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CStimGenDlg dialog

CStimGenDlg::CStimGenDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CStimGenDlg::IDD, pParent)
{
	//{{AFX_DATA_INIT(CStimGenDlg)
	m_status = _T("Hello");
	m_startCycle = 20000;
	m_irWord = _T("1100010110000");
	//}}AFX_DATA_INIT
	// Note that LoadIcon does not require a subsequent DestroyIcon in Win32
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CStimGenDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CStimGenDlg)
	DDX_Text(pDX, IDC_STATUS, m_status);
	DDX_Text(pDX, IDC_START_CYCLE, m_startCycle);
	DDX_Text(pDX, IDC_IR_WORD, m_irWord);
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CStimGenDlg, CDialog)
	//{{AFX_MSG_MAP(CStimGenDlg)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_BN_CLICKED(IDC_GEN_BUTT, OnGenButt)
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CStimGenDlg message handlers

BOOL CStimGenDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

	// Add "About..." menu item to system menu.

	// IDM_ABOUTBOX must be in the system command range.
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != NULL)
	{
		CString strAboutMenu;
		strAboutMenu.LoadString(IDS_ABOUTBOX);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// Set the icon for this dialog.  The framework does this automatically
	//  when the application's main window is not a dialog
	SetIcon(m_hIcon, TRUE);			// Set big icon
	SetIcon(m_hIcon, FALSE);		// Set small icon
	
	// TODO: Add extra initialization here
	
	return TRUE;  // return TRUE  unless you set the focus to a control
}

void CStimGenDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialog::OnSysCommand(nID, lParam);
	}
}

// If you add a minimize button to your dialog, you will need the code below
//  to draw the icon.  For MFC applications using the document/view model,
//  this is automatically done for you by the framework.

void CStimGenDlg::OnPaint() 
{
	if (IsIconic())
	{
		CPaintDC dc(this); // device context for painting

		SendMessage(WM_ICONERASEBKGND, (WPARAM) dc.GetSafeHdc(), 0);

		// Center icon in client rectangle
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// Draw the icon
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialog::OnPaint();
	}
}

// The system calls this to obtain the cursor to display while the user drags
//  the minimized window.
HCURSOR CStimGenDlg::OnQueryDragIcon()
{
	return (HCURSOR) m_hIcon;
}

void CStimGenDlg::OnGenButt() 
{
	FILE*	fp;
	UINT	c;
	int		i;
	CString	t;

	UpdateData(TRUE);

	c = m_startCycle;
	t = m_irWord;

	if (t.GetLength() != 13) {
		m_status = "Error: wrong number of character in IR Word";
		UpdateData(FALSE);
		return;
	}
	
	fp = fopen("irstim.sti", "wt");
	if (fp) {
		fprintf(fp, "CYCLE\tRB2\n");
		for (i=0 ; i<13 ; i++) {
			if (t[i] == '1') {
				fprintf(fp, "%d\t1\t;Etta\n", c);
				c += 480;
				fprintf(fp, "%d\t0\n", c);
				c += 2080;
			} else if (t[i] == '0') {
				fprintf(fp, "%d\t1\t;Nolla\n", c);
				c += 480;
				fprintf(fp, "%d\t0\n", c);
				c += 4600;
			} else {
				m_status = "IR Word contains illegal characters";
				UpdateData(FALSE);
				return;
			}
		}
		fclose(fp);
	}
	m_status = "Stim file created";
	UpdateData(FALSE);
}
