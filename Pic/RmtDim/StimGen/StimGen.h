// StimGen.h : main header file for the STIMGEN application
//

#if !defined(AFX_STIMGEN_H__BD7EECB4_A6AA_11D5_AE78_0060084CBD8A__INCLUDED_)
#define AFX_STIMGEN_H__BD7EECB4_A6AA_11D5_AE78_0060084CBD8A__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#ifndef __AFXWIN_H__
	#error include 'stdafx.h' before including this file for PCH
#endif

#include "resource.h"		// main symbols

/////////////////////////////////////////////////////////////////////////////
// CStimGenApp:
// See StimGen.cpp for the implementation of this class
//

class CStimGenApp : public CWinApp
{
public:
	CStimGenApp();

// Overrides
	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CStimGenApp)
	public:
	virtual BOOL InitInstance();
	//}}AFX_VIRTUAL

// Implementation

	//{{AFX_MSG(CStimGenApp)
		// NOTE - the ClassWizard will add and remove member functions here.
		//    DO NOT EDIT what you see in these blocks of generated code !
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};


/////////////////////////////////////////////////////////////////////////////

//{{AFX_INSERT_LOCATION}}
// Microsoft Visual C++ will insert additional declarations immediately before the previous line.

#endif // !defined(AFX_STIMGEN_H__BD7EECB4_A6AA_11D5_AE78_0060084CBD8A__INCLUDED_)
