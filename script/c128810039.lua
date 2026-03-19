--셀레스티얼 타이탄-분석가 제미아
local s,id=GetID()
function s.initial_effect(c)
	-- Pendulum Summon
	Pendulum.AddProcedure(c)

	-- E1: 빛 속성만 펜듈럼 소환 가능
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)

	-- E2: 파괴 + 엑스트라 덱 회수
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,id)
	e2:SetCategory(CATEGORY_DESTROY+CATEGORY_TOHAND)
	e2:SetCost(Cost.PayLP(1500))
	e2:SetTarget(s.tg)
	e2:SetOperation(s.op)
	c:RegisterEffect(e2)
end

s.listed_series={0xc02}
s.listed_names={id}

-- E1: 빛 속성만 펜듈럼 소환 가능
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_HAND+LOCATION_EXTRA)
		and (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
		and not c:IsAttribute(ATTRIBUTE_LIGHT)
end

-- 파괴 대상 (자신 필드 앞면 카드)
function s.desfilter(c)
	return c:IsFaceup() and c:IsControler(tp) and c:IsDestructable()
end

-- 엑스트라 덱 회수 필터
function s.thfilter(c)
	return c:IsFaceup()
		and c:IsSetCard(0xc02)
		and c:IsType(TYPE_PENDULUM)
		and c:IsAbleToHand()
end

-- 대상 지정
function s.tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_ONFIELD) and chkc:IsControler(tp) and chkc:IsFaceup() end
	if chk==0 then 
		return Duel.IsExistingTarget(aux.FaceupFilter(Card.IsDestructable),tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_EXTRA,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.FaceupFilter(Card.IsDestructable),tp,LOCATION_ONFIELD,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_EXTRA)
end

-- 실행
function s.op(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) and Duel.Destroy(tc,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_EXTRA,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end