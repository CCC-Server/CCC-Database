--Over Limit - Overheat
local s,id=GetID()
function s.initial_effect(c)
	--①: This card's name becomes "Limiter Removal" while on the field or in the GY.
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_SZONE+LOCATION_GRAVE)
	e1:SetCode(EFFECT_CHANGE_CODE)
	e1:SetValue(23171610) -- "Limiter Removal"
	c:RegisterEffect(e1)

	--②: Target 1 "Over Limit" monster you control; destroy 2 cards your opponent controls, and if you do, destroy that target.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_ACTIVATE)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	-- "You can only use 1 of the following effects ... per turn, and only once that turn."
	e2:SetCountLimit(1,id)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)

	--③: If "Limiter Removal" is activated: You can Set this card from your GY.
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	-- 같은 카운트 제한 공유 (②/③ 중 하나만 사용 가능)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.setcon)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)
end

-- "Limiter Removal"
s.listed_names={23171610}
-- "Over Limit" 카드군
s.listed_series={0xc48}

------------------------------------
-- ②번 효과: 파괴
------------------------------------
-- 내가 조종하는 "Over Limit" 몬스터
function s.olfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0xc48) and c:IsType(TYPE_MONSTER) and c:IsControler(tp)
end

function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsLocation(LOCATION_MZONE) and s.olfilter(chkc,tp)
	end
	if chk==0 then
		return Duel.IsExistingTarget(s.olfilter,tp,LOCATION_MZONE,0,1,nil,tp)
			and Duel.IsExistingMatchingCard(aux.TRUE,tp,0,LOCATION_ONFIELD,2,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local g=Duel.SelectTarget(tp,s.olfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,2,1-tp,LOCATION_ONFIELD)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not (tc and tc:IsRelateToEffect(e) and tc:IsFaceup()) then return end
	-- 상대 필드에서 카드 2장 선택
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,2,2,nil)
	if #g<2 then return end
	local ct=Duel.Destroy(g,REASON_EFFECT)
	-- 2장 모두 파괴에 성공했을 때만 대상 몬스터 파괴
	if ct==2 and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end

------------------------------------
-- ③번 효과: "Limiter Removal" 발동 시 묘지에서 세트
------------------------------------
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return re:IsHasType(EFFECT_TYPE_ACTIVATE) and rc:IsCode(23171610)
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsSSetable() end
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,c,1,0,0)
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.SSet(tp,c)
	end
end
