local s,id=GetID()
function s.initial_effect(c)
	--Xyz Summon
	Xyz.AddProcedure(c,nil,10,3)
	c:EnableReviveLimit()
	
	--Alternative Xyz Summon
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.ovcon)
	e0:SetOperation(s.ovop)
	e0:SetValue(SUMMON_TYPE_XYZ)
	c:RegisterEffect(e0)

	--① Destroy and inflict damage
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY+CATEGORY_DAMAGE)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCost(s.descost)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
end

--엑시즈 대체 소환 조건: "네메시스 퍼펫" 엑시즈 몬스터 위에 겹쳐 소환
function s.ovfilter(c,tp)
	return c:IsFaceup() and c:IsSetCard(0x763) and c:IsType(TYPE_XYZ)
end
function s.ovcon(e,c,og,min,max)
	if c==nil then return true end
	local tp=c:GetControler()
	--엑시즈 몬스터가 전투를 실행한 턴에만 가능
	return Duel.GetFlagEffect(tp,id)==0 and Duel.IsExistingMatchingCard(s.ovfilter,tp,LOCATION_MZONE,0,1,nil,tp)
end
function s.ovop(e,tp,eg,ep,ev,re,r,rp,c,og,min,max)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_XMATERIAL)
	local g=Duel.SelectMatchingCard(tp,s.ovfilter,tp,LOCATION_MZONE,0,1,1,nil,tp)
	local tc=g:GetFirst()
	if tc then
		local mg=tc:GetOverlayGroup()
		if #mg>0 then
			Duel.Overlay(c,mg)
		end
		c:SetMaterial(Group.FromCards(tc))
		Duel.Overlay(c,Group.FromCards(tc))
	end
	Duel.RegisterFlagEffect(tp,id,RESET_PHASE+PHASE_END,0,1) -- 1턴 1회 제한
end

--① 코스트: 엑시즈 소재 전부 제거
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:CheckRemoveOverlayCard(tp,c:GetOverlayCount(),REASON_COST) end
	c:RemoveOverlayCard(tp,c:GetOverlayCount(),c:GetOverlayCount(),REASON_COST)
end

--① 파괴 대상 지정
function s.desfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x763)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,0,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,#g*400)
end

--① 파괴 및 데미지 처리
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.desfilter,tp,LOCATION_MZONE,0,nil)
	if #g==0 then return end
	local ct=Duel.Destroy(g,REASON_EFFECT)
	if ct>0 then
		Duel.Damage(1-tp,ct*400,REASON_EFFECT)
	end
end
