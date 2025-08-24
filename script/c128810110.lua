--드래고니아-졸린 눈의 로턴드
local s,id=GetID()
function s.initial_effect(c)
	--① 묘지 제외하여 상대 몬스터를 뒷면 수비로
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_POSITION)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetCountLimit(1,id) -- 이 카드명의 효과는 1턴에 1번
	e1:SetCondition(s.poscon)
	e1:SetCost(aux.bfgcost) -- 묘지의 자신을 제외하는 표준 코스트
	e1:SetTarget(s.postg)
	e1:SetOperation(s.posop)
	c:RegisterEffect(e1)
end

s.listed_series={0xc05} -- "드래고니아"

-- 발동 조건: 상대 턴 + 드래고니아 싱크로 몬스터가 필드에 존재
function s.synfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc05) and c:IsType(TYPE_SYNCHRO)
end
function s.poscon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(1-tp) and Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- 대상 지정: 상대 필드 앞면 표시 몬스터 1장
function s.postg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsControler(1-tp) and chkc:IsFaceup() and chkc:IsLocation(LOCATION_MZONE) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_MZONE,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)
	local g=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,1,0,0)
end

-- 처리: 뒷면 수비 표시로 변경
function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and tc:IsFaceup() then
		Duel.ChangePosition(tc,POS_FACEDOWN_DEFENSE)
	end
end
