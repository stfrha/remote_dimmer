// StimGenDlg.h : header file
//

#if !defined(AFX_STIMGENDLG_H__BD7EECB6_A6AA_11D5_AE78_0060084CBD8A__INCLUDED_)
#define AFX_STIMGENDLG_H__BD7EECB6_A6AA_11D5_AE78_0060084CBD8A__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

/////////////////////////////////////////////////////////////////////////////
// CStimGenDlg dialog

class CStimGenDlg : public CDialog
{
// Construction
public:
	CStimGenDlg(CWnd* pParent = NULL);	// standard constructor

// Dialog Data
	//{{AFX_DATA(CStimGenDlg)
	enum { IDD = IDD_STIMGEN_DIALOG };
	CString	m_status;
	UINT	m_startCycle;
	CString	m_irWord;
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CStimGenDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	HICON m_hIcon;

	// Generated message map functions
	//{{AFX_MSG(CStimGenDlg)
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	afx_msg void OnGenButt();
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_STIMGENDLG_H__BD7EECB6_A6AA_11D5_AE78_0060084CBD8A__INCLUDED_)
