-- Fightcall Counter Scissors
local s,id=GetID()
function s.initial_effect(c)
	-- 카드군 표기: 0xc50 = "Fight Call"
	s.listed_series={0xc50}

	-- ①: 필드에서 발동한 상대 효과에 체인하여 발동, 그 카드를 패로 되돌림
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	-- 이 카드명의 ①의 효과는 1턴에 1번
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- ②: 묘지에서 제외하고 "Fightcall" 카드 세트
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCost(aux.bfgcost)
	-- 묘지로 보내진 턴에는 발동 불가
	e2:SetCondition(aux.exccon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
end

--------------------------------
-- ①번 효과 구현
--------------------------------
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	-- 상대(1-tp)가 발동했고, 발동 위치가 필드(LOCATION_ONFIELD)인 경우
	return rp==1-tp and re:GetActivateLocation()&LOCATION_ONFIELD~=0
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local rc=re:GetHandler()
	if chk==0 then return rc:IsAbleToHand() and rc:IsRelateToEffect(re) end
	-- 발동한 카드를 타겟으로 잡음 (일반적으로 "그 카드"를 지칭할 때 사용)
	Duel.SetTargetCard(rc)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,rc,1,0,0)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	-- 그 카드가 여전히 해당 효과와 연관되어 있고(필드에 존재하고) 패로 되돌릴 수 있다면
	if rc:IsRelateToEffect(re) then
		Duel.SendtoHand(rc,nil,REASON_EFFECT)
	end
end

--------------------------------
-- ②번 효과 구현
--------------------------------
function s.setfilter(c)
	return c:IsSetCard(0xc50) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(tp) and chkc:IsLocation(LOCATION_GRAVE) and s.setfilter(chkc) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingTarget(s.setfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectTarget(tp,s.setfilter,tp,LOCATION_GRAVE,0,1,1,e:GetHandler())
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) and Duel.GetLocationCount(tp,LOCATION_SZONE)>0 then
		Duel.SSet(tp,tc)
	end
end