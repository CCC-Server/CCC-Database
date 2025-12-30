--헤블론-콰트로 마누스 Mk.2
local s,id=GetID()
function s.initial_effect(c)
	--엑시즈 소환 절차: 레벨 9 몬스터 × 3
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsLevel,9),3)
	c:EnableReviveLimit()

	--랭크 업 엑시즈 소환 (랭크 8 위에 겹쳐 소환, 소재 1개 제거)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.rumcon)
	e0:SetOperation(s.rumop)
	c:RegisterEffect(e0)

	--① 공격력 상승: 소재 수 × 500
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.atkval)
	c:RegisterEffect(e1)

	--② 상대 필드 카드 효과 발동 시: 소재 2개 제거 → 그 카드를 소재로 함
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.ovcon)
	e2:SetCost(s.ovcost)
	e2:SetTarget(s.ovtg)
	e2:SetOperation(s.ovop)
	c:RegisterEffect(e2)
end

--랭크 업 소환 조건: 랭크 8 엑시즈 몬스터가 존재하고 소재 1개 제거 가능
function s.rumfilter(c,tp)
	return c:IsFaceup() and c:IsType(TYPE_XYZ) and c:IsRank(8) and c:IsControler(tp)
		and c:CheckRemoveOverlayCard(tp,1,REASON_COST)
end
function s.rumcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.rumfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end
function s.rumop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.rumfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	local tc=g:GetFirst()
	if tc then
		--소재 1개 제거
		tc:RemoveOverlayCard(tp,1,1,REASON_COST)
		--그 위에 겹쳐 소환
		local mg=tc:GetOverlayGroup()
		if #mg>0 then
			Duel.Overlay(c,mg)
		end
		c:SetMaterial(Group.FromCards(tc))
		Duel.Overlay(c,Group.FromCards(tc))
	end
end

--① 공격력 상승
function s.atkval(e,c)
	return c:GetOverlayCount()*500
end

--② 조건: 상대가 필드의 카드 효과 발동했을 때
function s.ovcon(e,tp,eg,ep,ev,re,r,rp)
	return rp==1-tp and re:GetHandler():IsOnField()
end
--② 코스트: 소재 2개 제거
function s.ovcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():CheckRemoveOverlayCard(tp,2,REASON_COST) end
	e:GetHandler():RemoveOverlayCard(tp,2,2,REASON_COST)
end
--② 대상: 상대 필드의 카드 1장
function s.ovtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) end
	if chk==0 then return Duel.IsExistingTarget(Card.IsAbleToOverlay,tp,0,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	Duel.SelectTarget(tp,Card.IsAbleToOverlay,tp,0,LOCATION_ONFIELD,1,1,nil)
end
--② 처리: 그 카드를 소재로 함
function s.ovop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if c:IsRelateToEffect(e) and tc and tc:IsRelateToEffect(e) then
		Duel.Overlay(c,Group.FromCards(tc))
	end
end