--드래고니아-격룡 브루트
local s,id=GetID()
function s.initial_effect(c)
	--① 묘지 제외하여 상대 마/함 파괴
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_GRAVE)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET) -- 대상 지정 플래그
	e1:SetCountLimit(1,id) -- 이 카드명의 효과는 1턴에 1번
	e1:SetCondition(s.descon)
	e1:SetCost(aux.bfgcost) -- 묘지의 자신을 제외하는 공통 코스트
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
end

s.listed_series={0xc05} -- "드래고니아"

-- 발동 조건: 상대 턴 + 자신 필드에 드래고니아 싱크로 몬스터 존재
function s.synfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xc05) and c:IsType(TYPE_SYNCHRO)
end
function s.descon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsTurnPlayer(1-tp) and Duel.IsExistingMatchingCard(s.synfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- 대상 지정: 상대 필드의 마/함 1장
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsType(TYPE_SPELL+TYPE_TRAP) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsType,tp,0,LOCATION_ONFIELD,1,nil,TYPE_SPELL+TYPE_TRAP) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,Card.IsType,tp,0,LOCATION_ONFIELD,1,1,nil,TYPE_SPELL+TYPE_TRAP)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

-- 처리: 선택된 카드 파괴
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
