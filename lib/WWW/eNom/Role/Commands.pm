package WWW::eNom::Role::Commands;

use Any::Moose "Role";
use strict;
use warnings;
use utf8;
use HTTP::Tiny;
use XML::LibXML::Simple qw(XMLin);

# VERSION

requires "_make_query_string";

=begin Pod::Coverage

 \w+

=end Pod::Coverage

=cut

# Create methods to support eNom API version 6.4:
my @commands = qw(
    AddBulkDomains AddContact AddDomainFolder AddToCart AdvancedDomainSearch
    AssignToDomainFolder AuthorizeTLD CertConfigureCert CertGetApproverEmail
    CertGetCertDetail CertGetCerts CertModifyOrder CertParseCSR CertPurchaseCert
    Check CheckLogin CheckNSStatus CommissionAccount Contacts CreateAccount
    CreateSubAccount DeleteAllPOPPaks DeleteContact DeleteCustomerDefinedData
    DeleteDomainFolder DeleteFromCart DeleteHostedDomain DeleteNameServer
    DeletePOP3 DeletePOPPak DeleteRegistration DeleteSubaccount DisableServices
    EnableServices Extend Extend_RGP ExtendDomainDNS Forwarding GetAccountInfo
    GetAccountPassword GetAccountValidation GetAddressBook GetAgreementPage
    GetAllAccountInfo GetAllDomains GetBalance GetCartContent GetCatchAll
    GetCerts GetConfirmationSettings GetContacts GetCusPreferences
    GetCustomerDefinedData GetCustomerPaymentInfo GetDNS GetDNSStatus
    GetDomainAuthInfo GetDomainCount GetDomainExp GetDomainFolderDetail GetDomainFolderList
    GetDomainInfo GetDomainMap GetDomainNameID GetDomainPhone GetDomains
    GetDomainServices GetDomainSLDTLD GetDomainSRVHosts GetDomainStatus
    GetDomainSubServices GetDotNameForwarding GetExpiredDomains GetExtAttributes
    GetExtendInfo GetForwarding GetGlobalChangeStatus
    GetGlobalChangeStatusDetail GetHomeDomainList GetHosts GetIPResolver
    GetMailHosts GetMetaTag GetOrderDetail GetOrderList GetPasswordBit GetPOP3
    GetPOPExpirations GetPOPForwarding GetRegHosts GetRegistrationStatus
    GetRegLock GetRenew GetReport GetResellerInfo GetSPFHosts GetServiceContact
    GetSubAccountDetails GetSubAccountPassword GetSubAccounts
    GetSubaccountsDetailList GetTLDList GetTransHistory GetWebHostingAll
    GetWhoisContact GetWPPSInfo GM_CancelSubscription GM_CheckDomain
    GM_GetCancelReasons GM_GetControlPanelLoginURL GM_GetRedirectScript
    GM_GetStatuses GM_GetSubscriptionDetails GM_GetSubscriptions
    GM_ReactivateSubscription GM_RenewSubscription GM_UpdateBillingCycle
    GM_UpdateSubscriptionDetails IM_UpdateSourceDomain InsertNewOrder ModifyNS
    ModifyNSHosting ModifyPOP3 NameSpinner ParseDomain PE_GetCustomerPricing
    PE_GetDomainPricing PE_GetPOPPrice PE_GetProductPrice PE_GetResellerPrice
    PE_GetRetailPrice PE_GetRetailPricing PE_GetRocketPrice PE_GetTLDID
    PE_SetPricing Preconfigure Purchase PurchaseHosting PurchasePOPBundle
    PurchasePreview PurchaseServices PushDomain RC_CancelSubscription
    RC_FreeTrialCheck RC_GetLoginToken RC_GetSubscriptionDetails
    RC_GetSubscriptions RC_RebillSubscription RC_ResetPassword
    RC_SetBillingCycle RC_SetPassword RC_SetSubscriptionDomain
    RC_SetSubscriptionName RefillAccount RegisterNameServer RemoveTLD
    RemoveUnsyncedDomains RenewPOPBundle RenewServices RP_CancelAccount
    RP_GetAccountDetail RP_GetAccounts RP_GetUpgradeOptions RP_GetUpgradePrice
    RP_RebillAccount RP_UpdateAccountName RP_UpgradeAccount RP_ValidateEmail
    RPT_GetReport SendAccountEmail ServiceSelect SetCatchAll
    SetCustomerDefinedData SetDNSHost SetDomainMap SetDomainPhone
    SetDomainSRVHosts SetDomainSubServices SetDotNameForwarding SetHosts
    SetIPResolver SetPakRenew SetPassword SetPOPForwarding SetRegLock SetRenew
    SetResellerServicesPricing SetResellerTLDPricing SetSPFHosts SetUpPOP3User
    StatusDomain SubAccountDomains SynchAuthInfo TEL_AddCTHUser
    TEL_GetCTHUserInfo TEL_GetCTHUserList TEL_GetPrivacy TEL_IsCTHUser
    TEL_UpdateCTHUser TEL_UpdatePrivacy TP_CancelOrder TP_CreateOrder
    TP_GetDetailsByDomain TP_GetOrder TP_GetOrderDetail TP_GetOrderReview
    TP_GetOrdersByDomain TP_GetOrderStatuses TP_GetTLDInfo TP_ResendEmail
    TP_ResubmitLocked TP_SubmitOrder TP_UpdateOrderDetail TS_AutoRenew
    TS_Configure TS_GetAccountDetail TS_GetAccounts UpdateAccountInfo
    UpdateAccountPricing UpdateCart UpdateCusPreferences UpdateDomainFolder
    UpdateExpiredDomains UpdateMetaTag UpdateNameServer UpdateNotificationAmount
    UpdatePushList UpdateRenewalSettings ValidatePassword WBLConfigure
    WBLGetCategories WBLGetFields WBLGetStatus WSC_GetAccountInfo
    WSC_GetAllPackages WSC_GetPricing WSC_Update_Ops
);

my $ua = HTTP::Tiny->new;
for my $command (@commands) {
    __PACKAGE__->meta->add_method(
        $command => sub {
            my ($self, @opts) = @_;
            my $uri = $self->_make_query_string($command, @opts);
            my $response = $ua->get($uri)->{content};
            my $response_type = $self->response_type;
            if ( $response_type eq "xml_simple" ) {
                $response = XMLin($response);
                $response->{errors} &&= [ values %{ $response->{errors} } ];
                $response->{responses} &&= $response->{responses}{response};
                $response->{responses} = [ $response->{responses} ]
                    if $response->{ResponseCount} == 1;
                foreach my $key ( keys %{$response} ) {
                    next unless $key =~ /(.*?)(\d+)$/x;
                    $response->{$1} = undef
                        if ref $response->{$key};
                    $response->{$1}[ $2 - 1 ] = delete $response->{$key};
                }
            }
            return $response;
        }
    );
}

1;
