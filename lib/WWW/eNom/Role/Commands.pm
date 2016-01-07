package WWW::eNom::Role::Commands;

use Moo::Role;
use strict;
use warnings;
use utf8;

use Class::Method::Modifiers 2.04 qw(fresh);
use HTTP::Tiny 0.031;
use XML::LibXML::Simple 0.91 qw(XMLin);

# VERSION

requires "_make_query_string";

=begin Pod::Coverage

 \w+

=end Pod::Coverage

=cut

# Create methods to support eNom API version 7.8:
my @commands = qw(
    AddBulkDomains AddContact AddDomainFolder AddDomainHeader AddHostHeader
    AddToCart AdvancedDomainSearch AM_AutoRenew AM_Configure AM_GetAccountDetail
    AM_GetAccounts AssignToDomainFolder AuthorizeTLD CalculateAllHostPackagePricing
    CalculateHostPackagePricing CancelHostAccount CancelOrder CertChangeApproverEmail
    CertConfigureCert CertGetApproverEmail CertGetCertDetail CertGetCerts CertModifyOrder
    CertParseCSR CertReissueCert CertPurchaseCert CertResendApproverEmail
    CertResendFulfillmentEmail Check CheckLogin CheckNSStatus CommissionAccount
    Contacts CreateAccount CreateHostAccount CreateSubAccount DeleteAllPOPPaks DeleteContact
    DeleteCustomerDefinedData DeleteDomainFolder DeleteDomainHeader DeleteFromCart
    DeleteHostedDomain DeleteHostHeader DeleteNameServer DeletePOP3 DeletePOPPak
    DeleteRegistration DeleteSubaccount DisableFolderApp DisableServices EnableFolderApp
    EnableServices Extend Extend_RGP ExtendDomainDNS Forwarding GetAccountInfo GetAccountPassword
    GetAccountValidation GetAddressBook GetAgreementPage GetAllAccountInfo GetAllDomains
    GetAllHostAccounts GetAllResellerHostPricing GetBalance GetCartContent GetCatchAll GetCerts
    GetConfirmationSettings GetContacts GetCusPreferences GetCustomerDefinedData GetCustomerPaymentInfo
    GetDNS GetDNSStatus GetDomainCount GetDomainExp GetDomainFolderDetail GetDomainFolderList
    GetDomainHeader GetDomainInfo GetDomainNameID GetDomains GetDomainServices GetDomainSLDTLD
    GetDomainSRVHosts GetDomainStatus GetDomainSubServices GetDotNameForwarding GetExpiredDomains
    GetExtAttributes GetExtendInfo GetFilePermissions GetForwarding GetGlobalChangeStatus
    GetGlobalChangeStatusDetail GetHomeDomainList GetHostAccount GetHostAccounts GetHostHeader GetHosts
    GetIDNCodes GetIPResolver GetMailHosts GetMetaTag GetNameSuggestions GetNews GetOrderDetail
    GetOrderList GetPasswordBit GetPOP3 GetPOPExpirations GetPOPForwarding GetProductNews
    GetProductSelectionList GetRegHosts GetRegistrationStatus GetRegLock GetRenew GetReport
    GetResellerHostPricing GetResellerInfo GetServiceContact GetSPFHosts GetStorageUsage
    GetSubAccountDetails GetSubAccountPassword GetSubAccounts GetSubaccountsDetailList GetTLDDetails
    GetTLDList GetTransHistory GetWebHostingAll GetWhoisContact GetWPPSInfo GM_CancelSubscription
    GM_CheckDomain GM_GetCancelReasons GM_GetControlPanelLoginURL GM_GetRedirectScript GM_GetStatuses
    GM_GetSubscriptionDetails GM_GetSubscriptions GM_ReactivateSubscription GM_RenewSubscription
    GM_UpdateBillingCycle GM_UpdateSubscriptionDetails HostPackageDefine HostPackageDelete HostPackageModify
    HostPackageView HostParkingPage InsertNewOrder IsFolderEnabled ListDomainHeaders ListHostHeaders
    ListWebFiles MetaBaseGetValue MetaBaseSetValue ModifyDomainHeader ModifyHostHeader ModifyNS
    ModifyNSHosting ModifyPOP3 MySQL_GetDBInfo NameSpinner NM_CancelOrder NM_ExtendOrder
    NM_GetPremiumDomainSettings NM_GetSearchCategories NM_ProcessOrder NM_Search
    NM_SetPremiumDomainSettings ParseDomain PE_GetCustomerPricing PE_GetDomainPricing PE_GetEapPricing
    PE_GetPOPPrice PE_GetPremiumPricing PE_GetProductPrice PE_GetResellerPrice PE_GetRetailPrice
    PE_GetRetailPricing PE_GetRocketPrice PE_GetTLDID PE_SetPricing PP_CancelSubscription PP_CheckUpgrade
    PP_GetCancelReasons PP_GetControlPanelLoginURL PP_GetStatuses PP_GetSubscriptionDetails PP_GetSubscriptions
    PP_ReactivateSubscription PP_UpdateSubscriptionDetails PP_ValidatePassword Portal_GetDomainInfo
    Portal_GetAwardedDomains Portal_GetToken Portal_UpdateAwardedDomains PreConfigure Purchase PurchaseHosting
    PurchasePOPBundle PurchasePreview PurchaseServices PushDomain Queue_GetInfo Queue_GetExtAttributes
    Queue_DomainPurchase Queue_GetDomains Queue_GetOrders Queue_GetOrderDetail RAA_GetInfo RAA_ResendNotification
    RC_CancelSubscription RC_FreeTrialCheck RC_GetLoginToken RC_GetSubscriptionDetails RC_GetSubscriptions
    RC_RebillSubscription RC_ResetPassword RC_SetBillingCycle RC_SetPassword RC_SetSubscriptionDomain
    RC_SetSubscriptionName RefillAccount RegisterNameServer RemoveTLD RemoveUnsyncedDomains RenewPOPBundle
    RenewServices RPT_GetReport SendAccountEmail ServiceSelect SetCatchAll SetCustomerDefinedData SetDNSHost
    SetDomainSRVHosts SetDomainSubServices SetDotNameForwarding SetFilePermissions SetHosts SetIPResolver
    SetPakRenew SetPassword SetPOPForwarding SetRegLock SetRenew SetResellerServicesPricing SetResellerTLDPricing
    SetSPFHosts SetUpPOP3User SL_AutoRenew SL_Configure SL_GetAccountDetail SL_GetAccounts StatusDomain
    SubAccountDomains SynchAuthInfo TEL_AddCTHUser TEL_GetCTHUserInfo TEL_GetCTHUserList TEL_GetPrivacy TEL_IsCTHUser
    TEL_UpdateCTHUser TEL_UpdatePrivacy TLD_AddWatchlist TLD_DeleteWatchlist TLD_GetTLD TLD_GetWatchlist
    TLD_GetWatchlistTlds TLD_Overview TLD_PortalGetAccountInfo TLD_PortalUpdateAccountInfo TM_Check TM_GetNotice
    TM_UpdateCart TP_CancelOrder TP_CreateOrder TP_GetDetailsByDomain TP_GetOrder TP_GetOrderDetail TP_GetOrderReview
    TP_GetOrdersByDomain TP_GetOrderStatuses TP_GetTLDInfo TP_ResendEmail TP_ResubmitLocked TP_SubmitOrder
    TP_UpdateOrderDetail TS_AutoRenew TS_Configure TS_GetAccountDetail TS_GetAccounts UpdateAccountInfo
    UpdateAccountPricing UpdateCart UpdateCusPreferences UpdateDomainFolder UpdateExpiredDomains
    UpdateHostPackagePricing UpdateMetaTag UpdateNameServer UpdateNotificationAmount UpdatePushList
    UpdateRenewalSettings ValidatePassword WBLConfigure WBLGetCategories WBLGetFields WBLGetStatus
    WebHostCreateDirectory WebHostCreatePOPBox WebHostDeletePOPBox WebHostGetCartItem WebHostGetOverageOptions
    WebHostGetOverages WebHostGetPackageComponentList WebHostGetPackageMinimums WebHostGetPackages WebHostGetPOPBoxes
    WebHostGetResellerPackages WebHostGetStats WebHostHelpInfo WebHostSetCustomPackage WebHostSetOverageOptions
    WebHostUpdatePassword WebHostUpdatePOPPassword WSC_GetAccountInfo WSC_GetAllPackages WSC_GetPricing WSC_Update_Ops
    XXX_GetMemberId XXX_RemoveMemberId XXX_SetMemberId
);

has _ua => (is => 'lazy', builder => sub { HTTP::Tiny->new });

fresh $_ => __PACKAGE__->_make_command_coderef($_)
    for @commands;

sub _make_command_coderef {
    my (undef, $command) = @_;

    return sub {
        my ($self, @opts) = @_;
        my $uri = $self->_make_query_string($command, @opts);
        my $response = $self->_ua->get($uri)->{content};
        my $response_type = $self->response_type;
        if ( $response_type eq "xml_simple" ) {
            $response = XMLin($response);
            $response->{errors} &&= [ values %{ $response->{errors} } ];
            $response->{responses} &&= $response->{responses}{response};
            $response->{responses} = [ $response->{responses} ]
                if $response->{ResponseCount} == 1;
            foreach my $key ( keys %{$response} ) {
                next unless $key =~ /(.*?)(\d+)$/;
                $response->{$1} = undef if ref $response->{$key};
                $response->{$1}[ $2 - 1 ] = delete $response->{$key};
            }
        }
        return $response;
    };
}

1;
